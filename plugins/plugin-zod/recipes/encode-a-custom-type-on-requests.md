---
layout: doc
title: Encode a custom type on requests
description: Use a direction-aware printer node so a domain type decodes on responses and encodes back to the wire format on requests, including through a $ref.
outline: deep
---

# Encode a custom type on requests

A field can travel as an ISO string and be a `Temporal.PlainTime` in your code. Responses decode, requests encode.

Printer node handlers read `this.options.direction`: `'decode'` for response schemas, `'encode'` for request bodies and parameters.

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

## Limits

### The generated types describe the wire shape

If the client is also typed by `@kubb/plugin-ts`, its request and response types come from the spec, so a `format: 'time'` field is typed `string` there whatever the Zod schema converts it to at runtime. Drop `pluginTs` and add `inferred: true` on `pluginZod` instead, and `pluginFetch` or `pluginAxios` types the operation from `z.infer` on this schema, which follows the conversion.

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
