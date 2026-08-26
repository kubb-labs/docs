---
layout: doc
title: Encode a custom type on requests
description: Use a direction-aware printer node so a domain type decodes on responses and encodes back to the wire format on requests.
outline: deep
---

# Encode a custom type on requests

A field can travel as an ISO string and be a `Temporal.PlainTime` in your code. Responses decode, requests encode.

Printer node handlers read `this.options.direction`: `'output'` for response schemas, `'input'` for request bodies and parameters. Branch on it to emit a different Zod chain per direction.

::: warning Read the limits first
This works for a request body written inline in the operation. A `$ref` body keeps the decode direction, and the generated types describe the wire shape. Both are covered in [Limits](#limits).
:::

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'
import type { PrinterZodNodes } from '@kubb/plugin-zod'

const nodes: PrinterZodNodes = {
  time() {
    return this.options.direction === 'input'
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
> Annotate the handler map as `PrinterZodNodes`. The `printer.nodes` option also accepts the Zod Mini shape, which has no `direction`, so an inline object literal fails to typecheck with `Property 'direction' does not exist on type 'PrinterZodMiniOptions'`. Writing `nodes` as a separate annotated constant picks the standard printer.

## Output example

One handler covers both. The response decodes, the body encodes.

```typescript [src/gen/zod/bookSlotSchema.ts]
export const bookSlotStatus201Schema = z.object({
  startsAt: z.iso.time().transform((value) => Temporal.PlainTime.from(value)),
})

export const bookSlotResponseSchema = bookSlotStatus201Schema

export const bookSlotBodySchema = z.object({
  startsAt: z.instanceof(Temporal.PlainTime).transform((value) => value.toString()),
})
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

### A $ref request body keeps the decode direction

Kubb emits the encode variant of a component schema only when it knows that schema carries a conversion. A `printer.nodes` handler is invisible to that check, so a `$ref` body resolves to the decode schema:

```typescript [src/gen/zod/bookRefSlotSchema.ts]
export const bookRefSlotResponseSchema = slotSchema
export const bookRefSlotBodySchema = slotSchema // decode, not encode
```

Register a [codec](/plugins/plugin-zod/recipes/write-a-custom-codec) instead, or write the body schema inline in the operation. Most specs `$ref` their bodies, so check your generated `<operation>BodySchema` before relying on this.

### The generated types describe the wire shape

Request and response types come from `@kubb/plugin-ts`, which reads the spec. There a `format: 'time'` field is typed `string`, whatever the Zod schema converts it to at runtime.

### Temporal needs a polyfill

The generated code references `Temporal` as a global. Until your runtime ships it, load a polyfill that installs the global with its types, and make sure that import runs first.

## Built-in date conversion

Dates already work this way with no configuration, and without the `$ref` limit above. Set `dateType: 'date'` on the adapter and a `date-time` field decodes to a `Date` on responses and encodes back to an ISO string on requests.

```typescript [src/gen/zod/orderSchema.ts]
export const orderSchema = z.object({
  shipDate: z.iso.datetime().transform((value) => new Date(value)).optional(),
})

export const orderInputSchema = z.object({
  shipDate: z.date().transform((value) => value.toISOString()).optional(),
})
```

Request bodies reference `orderInputSchema` and responses reference `orderSchema`, including through a `$ref`.
