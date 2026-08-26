---
layout: doc
title: Encode a custom type on requests
description: Use a direction-aware printer node so a domain type decodes on responses and encodes back to the wire format on requests.
outline: deep
---

# Encode a custom type on requests

A field can travel as a string but live in your code as something richer, such as a `Temporal.PlainTime`. That needs two different conversions. A response decodes the wire string into the domain value, and a request encodes the domain value back into a string.

Printer node handlers read `this.options.direction`, which is `'output'` for response schemas and `'input'` for request bodies and parameters. Branch on it to emit a different Zod chain per direction.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'
import type { PrinterZodNodes } from '@kubb/plugin-zod'

const nodes: PrinterZodNodes = {
  string(node) {
    if (node.format !== 'time') return this.base(node)

    return this.options.direction === 'input'
      ? 'z.instanceof(Temporal.PlainTime).transform((value) => value.toString())'
      : 'z.string().transform((value) => Temporal.PlainTime.from(value))'
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

Returning `this.base(node)` for every other format keeps the built-in `string` handler for fields you are not converting.

> [!IMPORTANT]
> Annotate the handler map as `PrinterZodNodes`. The `printer.nodes` option also accepts the Zod Mini shape, which has no `direction`, so an inline object literal fails to typecheck with `Property 'direction' does not exist on type 'PrinterZodMiniOptions'`. Writing `nodes` as a separate annotated constant picks the standard printer.

## Output example

```typescript [src/gen/zod/bookSlotSchema.ts]
export const bookSlotStatus201Schema = z.object({
  startsAt: z.string().transform((value) => Temporal.PlainTime.from(value)),
})

export const bookSlotResponseSchema = bookSlotStatus201Schema

export const bookSlotBodySchema = z.object({
  startsAt: z.instanceof(Temporal.PlainTime).transform((value) => value.toString()),
})
```

The response schema decodes and the body schema encodes, from one handler.

## Why this works with a client validator

Both schemas are ordinary Zod schemas built from `.transform()`, so both satisfy [Standard Schema](https://standardschema.dev). A client plugin validates through `~standard.validate` without knowing a conversion is happening.

That matters because `~standard.validate` runs a schema in one direction only. Setting [`validator`](/plugins/plugin-fetch/reference/options#validator) on `pluginFetch` or `pluginAxios` picks up the right schema for each slot on its own: `validator.request` gets the body schema, which already encodes, and `validator.response` gets the response schema, which already decodes.

```typescript [kubb.config.ts]
pluginFetch({
  output: { path: 'clients', mode: 'directory' },
  validator: { request: 'zod', response: 'zod' },
})
```

```typescript [usage.ts]
import { bookSlot } from './src/gen/clients/bookSlot'

// startsAt goes out as '09:30:00' and comes back as a Temporal.PlainTime
const { data } = await bookSlot({ body: { startsAt: Temporal.PlainTime.from('09:30') } })
```

`Temporal` is referenced as a global in the generated code. Load a polyfill in your app entry point until your runtime ships it natively.

## Built-in date conversion

Dates already work this way with no configuration. Set `dateType: 'date'` on the adapter and a `date-time` field decodes to a `Date` on responses and encodes back to an ISO string on requests.

```typescript [src/gen/zod/orderSchema.ts]
export const orderSchema = z.object({
  shipDate: z.iso.datetime().transform((value) => new Date(value)).optional(),
})

export const orderInputSchema = z.object({
  shipDate: z.date().transform((value) => value.toISOString()).optional(),
})
```

Request bodies reference `orderInputSchema` and responses reference `orderSchema`. Use the recipe above for any type that needs the same treatment.
