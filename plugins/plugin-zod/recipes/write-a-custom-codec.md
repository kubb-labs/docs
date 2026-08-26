---
layout: doc
title: Write a custom codec
description: Register a two-way conversion so a schema type decodes on responses and encodes back to its wire format on requests, including through a $ref.
outline: deep
---

# Write a custom codec

Some fields travel as one type and are used as another. An OpenAPI `time` field arrives as the string `"09:30:00"`, but the code that handles it would rather have a `Temporal.PlainTime`. That needs two conversions going opposite ways, and which one applies depends on the direction of the call.

A codec is that pair. Register one on [`codecs`](/plugins/plugin-zod/reference/options#codecs) and plugin-zod prints `decode` into response schemas and `encode` into request schemas.

## The shape

A codec has three members. `matches` picks the nodes it applies to, and the two directions return the Zod expression as a string.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'
import type { Codec } from '@kubb/plugin-zod'

const plainTimeCodec: Codec = {
  matches: (node) => node.type === 'time',
  decode: () => 'z.iso.time().transform((value) => Temporal.PlainTime.from(value))',
  encode: () => 'z.instanceof(Temporal.PlainTime).transform((value) => value.toString())',
}

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      codecs: [plainTimeCodec],
    }),
  ],
})
```

`decode` starts from `z.iso.time()` rather than a bare `z.string()` on purpose. An unchecked string reaching `Temporal.PlainTime.from` throws a `RangeError` out of the transform, where the same bad value would otherwise surface as the validation issue a client validator reports.

## Match the node type, not the format

`matches` receives a schema node from Kubb's AST, not the raw OpenAPI schema. The adapter has already turned `format: 'time'` into a node of type `time`, so match on that. The same holds for `date` and `date-time`, which become `date` and `datetime` nodes.

```typescript
matches: (node) => node.type === 'time'        // correct
matches: (node) => node.format === 'time'      // never fires, a time node carries no format
```

Both direction functions receive the node as well, so one codec can vary its output across the nodes it matches:

```typescript
const temporalCodec: Codec = {
  matches: (node) => node.type === 'time' || node.type === 'datetime',
  decode: (node) =>
    node.type === 'time'
      ? 'z.iso.time().transform((value) => Temporal.PlainTime.from(value))'
      : 'z.iso.datetime().transform((value) => Temporal.Instant.from(value))',
  encode: (node) =>
    node.type === 'time'
      ? 'z.instanceof(Temporal.PlainTime).transform((value) => value.toString())'
      : 'z.instanceof(Temporal.Instant).transform((value) => value.toString())',
}
```

## What gets generated

A component carrying the type is emitted twice. The canonical schema decodes, and an `InputSchema` variant encodes:

```typescript [src/gen/zod/slotSchema.ts]
export const slotSchema = z.object({
  startsAt: z.iso.time().transform((value) => Temporal.PlainTime.from(value)),
})

export const slotInputSchema = z.object({
  startsAt: z.instanceof(Temporal.PlainTime).transform((value) => value.toString()),
})
```

Operations then reference whichever direction fits. A response points at the decode schema and a request body at the encode one, and this holds when the body is a `$ref`:

```typescript [src/gen/zod/bookSlotSchema.ts]
export const bookSlotStatus201Schema = slotSchema      // decode
export const bookSlotBodySchema = slotInputSchema      // encode
```

## Using it with a client

Both sides are ordinary Zod schemas built from `.transform()`, so both satisfy [Standard Schema](https://standardschema.dev). Setting [`validator`](/plugins/plugin-fetch/reference/options#validator) on `pluginFetch` or `pluginAxios` picks the right schema per slot on its own, and the client runs each through `~standard.validate` without knowing a conversion happened.

```typescript [kubb.config.ts]
pluginFetch({
  output: { path: 'clients', mode: 'directory' },
  validator: { request: 'zod', response: 'zod' },
})
```

```typescript [usage.ts]
import { bookSlot } from './src/gen/clients/bookSlot'

// startsAt goes out as '09:30:00'
await bookSlot({ body: { startsAt: Temporal.PlainTime.from('09:30') } })
```

Two things to know before you rely on this. The generated request and response types come from `@kubb/plugin-ts`, which reads the spec, so a `time` field is typed `string` there whatever the schema converts it to. The conversion is a runtime one and the types will not show it. And `Temporal` is referenced as a global, so until your runtime ships it, load a polyfill that installs the global along with its types, before any generated schema runs.

## Replacing the built-in date codec

Registered codecs are checked before the built-in one, so matching `date` takes it over. This turns date fields into Luxon `DateTime` instead of `Date`:

```typescript
const luxonCodec: Codec = {
  matches: (node) => node.type === 'date' || node.type === 'datetime',
  decode: () => 'z.iso.datetime().transform((value) => DateTime.fromISO(value))',
  encode: () => 'z.instanceof(DateTime).transform((value) => value.toISO())',
}
```

## When a printer node is the better fit

[`printer.nodes`](/plugins/plugin-zod/reference/options#printer) replaces how a node prints. Use it when a type needs no conversion and you only want different output, such as printing `int64` as `z.number()` instead of `z.bigint()`.

It cannot stand in for a codec. A node handler changes the printed output without telling the generator that the schema carries a conversion, so no `InputSchema` variant is emitted and a `$ref` request body keeps the decode direction. Reach for `codecs` whenever the two directions differ.
