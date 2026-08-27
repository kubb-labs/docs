---
layout: doc
title: Encode a custom type on requests
description: Use a direction-aware printer node so a domain type decodes on responses and encodes back to the wire format on requests, including through a $ref.
outline: deep
---

# Encode a custom type on requests

A field can travel as an ISO string and be a `Temporal.PlainTime` in your code. Responses decode, requests encode.

Printer node handlers read `this.options.direction`: `'decode'` for response schemas, `'encode'` for request bodies and parameters. Branch on it and plugin-zod notices the two outputs differ, then emits an `${name}InputSchema` variant for request bodies to resolve to, `$ref` included.

The values name the conversion rather than the slot, because Zod's own `z.input` and `z.output` describe a different axis and read inverted here: the `'decode'` schema is the one whose `z.input` is the wire type.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'
import type { PrinterZodNodes } from '@kubb/plugin-zod'

const nodes: PrinterZodNodes = {
  time() {
    return this.options.direction === 'encode'
      ? 'z.instanceof(Temporal.PlainTime).transform((value) => value.toString())'
      : 'z.iso.time().transform((value) => Temporal.PlainTime.from(value))'
  },
}

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      printer: { nodes },
    }),
  ],
})
```

Override the `time` node, not `string`. An OpenAPI `format: 'time'` field parses to a `time` node, so a `string` handler never sees it. The same holds for `date` and `date-time`, which parse to `date` and `datetime` nodes.

Decode from `z.iso.time()`, not a bare `z.string()`. An unchecked string reaching `Temporal.PlainTime.from` throws a `RangeError` out of the transform, instead of surfacing as the `ParseError` a client validator raises.

> [!IMPORTANT]
> Annotate the handler map as `PrinterZodNodes`. `printer.nodes` also accepts the Zod Mini shape, which has no `direction`, so an inline object literal fails to typecheck with `Property 'direction' does not exist on type 'PrinterZodMiniOptions'`. A separate annotated constant picks the standard printer.

## Output example

A component carrying the type is emitted twice, and a `$ref` request body resolves to the input one:

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

## Why this works with a client validator

`~standard.validate` runs a schema in one direction only, but both schemas are ordinary Zod built from `.transform()`, so each satisfies [Standard Schema](https://standardschema.dev) on its own. Setting [`validator`](/plugins/plugin-fetch/reference/options#validator) on `pluginFetch` or `pluginAxios` picks the right one per slot: `validator.request` gets the body schema, which encodes, and `validator.response` gets the response schema, which decodes.

```typescript [kubb.config.ts]
pluginFetch({
  output: { path: 'clients', mode: 'directory' },
  validator: { request: 'zod', response: 'zod' },
})
```

## Limits

### The generated types describe the wire shape

If the client is also typed by `@kubb/plugin-ts`, its request and response types come from the spec, so a `format: 'time'` field is typed `string` there whatever the Zod schema converts it to at runtime. Drop `pluginTs` and add `inferred: true` on `pluginZod` instead, and `pluginFetch` or `pluginAxios` types the operation from `z.infer` on this schema, which follows the conversion.

### Temporal needs a polyfill

The generated code references `Temporal` as a global. Until your runtime ships it, load a polyfill that installs the global with its types, and make sure that import runs first.

## Built-in date conversion

Dates already work this way with no configuration. Set `dateType: 'date'` on the adapter and a `date-time` field decodes to a `Date` on responses and encodes back to an ISO string on requests, through a `$ref` too:

```typescript [src/gen/zod/orderSchema.ts]
export const orderSchema = z.object({
  shipDate: z.iso.datetime().transform((value) => new Date(value)).optional(),
})

export const orderInputSchema = z.object({
  shipDate: z.date().transform((value) => value.toISOString()).optional(),
})
```

The built-in `date` handler branches on `direction` exactly like a custom one. Overriding `printer.nodes.date` replaces it whole, that branch included.
