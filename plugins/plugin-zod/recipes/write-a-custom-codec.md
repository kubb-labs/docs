---
layout: doc
title: Write a custom codec
description: Register a two-way conversion so a schema type decodes on responses and encodes back to its wire format on requests, including through a $ref.
outline: deep
---

# Write a custom codec

An OpenAPI `time` field arrives as `"09:30:00"` but your code wants a `Temporal.PlainTime`. That is two conversions, and which one applies depends on the direction of the call.

A codec is that pair. Register one on [`codecs`](/plugins/plugin-zod/reference/options#codecs) and plugin-zod prints `decode` into response schemas and `encode` into request schemas.

## The shape

`matches` picks the nodes, and the two directions return a Zod expression as a string.

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

Decode from `z.iso.time()`, not a bare `z.string()`. A validated value fails as a validation issue. An unchecked one throws a `RangeError` out of the middle of the transform, which is much harder to trace back to the field.

## Match the node type, not the format

`matches` receives a node from Kubb's AST, not the raw OpenAPI schema. The adapter has already turned `format: 'time'` into a `time` node. The same holds for `date` and `date-time`, which become `date` and `datetime` nodes.

```typescript
matches: (node) => node.type === 'time'        // correct
matches: (node) => node.format === 'time'      // never fires, a time node carries no format
```

Both directions receive the node, so one codec can cover several types:

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

A component carrying the type is emitted twice, and operations reference whichever direction fits. This holds when the body is a `$ref`:

```typescript [src/gen/zod/slotSchema.ts]
export const slotSchema = z.object({
  startsAt: z.iso.time().transform((value) => Temporal.PlainTime.from(value)),
})

export const slotInputSchema = z.object({
  startsAt: z.instanceof(Temporal.PlainTime).transform((value) => value.toString()),
})
```

```typescript [src/gen/zod/bookSlotSchema.ts]
export const bookSlotStatus201Schema = slotSchema      // decode
export const bookSlotBodySchema = slotInputSchema      // encode
```

## Using it with a client

Both sides are ordinary Zod built from `.transform()`, so both satisfy [Standard Schema](https://standardschema.dev). Set [`validator`](/plugins/plugin-fetch/reference/options#validator) on `pluginFetch` or `pluginAxios` and it picks the right schema per slot, then runs it through `~standard.validate` without knowing a conversion happened.

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

One thing to expect: if the client is also typed by `@kubb/plugin-ts`, its types will not follow the value. `plugin-ts` reads the spec, so a `time` field is typed `string` there whatever the schema converts it to at runtime. Drop `pluginTs` and add `inferred: true` here instead, and `pluginFetch` or `pluginAxios` types the operation from `z.infer` on this schema, so `startsAt` comes back typed `Temporal.PlainTime`.

`Temporal` is also referenced as a global. Until your runtime ships it, load a polyfill that installs the global with its types, and make sure that import runs first.

## Replacing the built-in date codec

Registered codecs are checked first, so matching `date` takes the built-in over. It is all or nothing: your codec owns both directions for every node it matches, including the `YYYY-MM-DD` case the built-in handles separately.

```typescript
const luxonCodec: Codec = {
  matches: (node) => node.type === 'date' || node.type === 'datetime',
  decode: () => 'z.iso.datetime().transform((value) => DateTime.fromISO(value))',
  encode: () => 'z.instanceof(DateTime).transform((value) => value.toISO())',
}
```

## When a printer node is the better fit

[`printer.nodes`](/plugins/plugin-zod/reference/options#printer) replaces how a node prints. Use it when a type needs no conversion and you only want different output, such as printing `int64` as `z.number()` instead of `z.bigint()`.

It cannot stand in for a codec. A node handler changes the output without telling the generator the schema carries a conversion, so no `InputSchema` variant is emitted and a `$ref` request body keeps the decode direction. Reach for `codecs` whenever the two directions differ.
