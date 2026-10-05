---
layout: doc
title: Customize generated schemas
description: Prefix inferred types, change Zod validators, and encode custom request types.
outline: deep
---

# Customize generated schemas

Start with the [Zod plugin configuration](/plugins/plugin-zod/#example). Apply these changes to `pluginZod()` in that configuration.

## Prefix inferred types

Enable `inferred` and override `resolver.schema.typeName`.

```typescript [kubb.config.ts]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  inferred: true,
  resolver: {
    schema: {
      typeName(name) {
        return 'Api' + name
      },
    },
  },
})
```

The type becomes `ApiPet`. The schema constant stays `petSchema`. The callback receives the cased type name, so no additional casing helper is needed.

## Use numbers for int64 fields

Replace the `bigint` printer handler to validate `int64` fields with `z.number()`.

```typescript [kubb.config.ts]
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      bigint() {
        return 'z.number()'
      },
    },
  },
})
```

The `integer` handler controls `int32` fields separately. To change integer representation across all plugins, use the adapter's [`integerType`](/adapters/adapter-oas/reference/options#integertype).

## Remove descriptions

Use the [description-removal macro](/plugins/plugin-ts/guide/customization#remove-descriptions) with `pluginZod({ macros: [dropDescriptions] })`. Generated schemas omit description metadata.

## Encode custom types

A direction-aware printer decodes response values and encodes request values. This example converts ISO time strings to `Temporal.PlainTime`.

```typescript [kubb.config.ts]
import { pluginZod, type PrinterZodNodes } from '@kubb/plugin-zod'

const nodes: PrinterZodNodes = {
  time() {
    return this.options.direction === 'encode'
      ? 'z.instanceof(Temporal.PlainTime).transform((value) => value.toString())'
      : 'z.iso.time().transform((value) => Temporal.PlainTime.from(value))'
  },
}

pluginZod({ inferred: true, printer: { nodes } })
```

Use a runtime that provides `Temporal`, or add its polyfill through a generated import or banner. Match the OpenAPI format: `time`, `date`, and `date-time` use `time`, `date`, and `datetime` handlers.

The generator emits separate response and input schemas, including through `$ref`:

```typescript [src/gen/zod/slotSchema.ts]
export const slotSchema = z.object({
  startsAt: z.iso.time().transform((value) => Temporal.PlainTime.from(value)),
})

export const slotInputSchema = z.object({
  startsAt: z.instanceof(Temporal.PlainTime).transform((value) => value.toString()),
})
```

Use `inferred: true` without `pluginTs` so the client types follow these conversions. Types from `pluginTs` describe the wire format.

For built-in date conversion, set `dateType: 'date'` on the adapter. Generated response schemas convert ISO datetimes to `Date`. Request schemas convert them back with `toISOString()`.

## Import a custom codec

Override a printer node and register the package import with `this.import`. For example, use your package's `myCodec.uint64()` for `int64` fields:

```typescript [kubb.config.ts]
import { ast } from 'kubb/kit'
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      bigint() {
        this.import(ast.factory.createImport({
          name: ['myCodec'],
          path: 'my-codec/zod',
        }))
        return 'myCodec.uint64()'
      },
    },
  },
})
```

Generated files import `myCodec` from `my-codec/zod`. Leave `root` unset on this import to preserve the package specifier. Setting `root` rewrites it as a relative file path.
