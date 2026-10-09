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

> [!IMPORTANT]
> Use `inferred: true` without `pluginTs` so the client types follow these conversions. Types from `pluginTs` describe the wire format.

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

## Format and type mappings

`@kubb/plugin-zod` generates native Zod v4 schemas for standard OpenAPI types and formats:

| OpenAPI Type / Format | Standard Zod Output | Zod Mini Output | Notes |
| :--- | :--- | :--- | :--- |
| `integer` | `z.int()` | `z.int()` | Coerces to `z.coerce.number().int()` when `coercion.numbers` is enabled |
| `integer`, `format: int32` | `z.int32()` | `z.int32()` | 32-bit signed integer |
| `integer`, `format: uint32` | `z.uint32()` | `z.uint32()` | 32-bit unsigned integer |
| `integer`, `format: int64` | `z.bigint()` | `z.bigint()` | 64-bit integer |
| `string`, `format: byte` / `base64` | `z.base64()` | `z.base64()` | Base64 string validation |
| `string`, `format: base64url` | `z.base64url()` | `z.base64url()` | URL-safe base64 string validation |
| `string`, `format: jwt` | `z.jwt()` | `z.jwt()` | JSON Web Token format |
| `string`, `format: ulid` | `z.ulid()` | `z.ulid()` | ULID format |
| `string`, `format: iban` | `z.iban()` | `z.iban()` | International Bank Account Number |
| `string`, `format: duration` | `z.iso.duration()` | `z.iso.duration()` | ISO 8601 duration format |
| `string`, `format: uuid` | `z.uuid()` (or `z.guid()`) | `z.uuid()` (or `z.guid()`) | Configured via `guidType` |
| `string`, `format: email` | `z.email()` | `z.email()` | Email format |
| `string`, `format: uri` / `url` | `z.url()` | `z.url()` | URL format |
| `string`, `format: ipv4` / `ipv6` | `z.ipv4()` / `z.ipv6()` | `z.ipv4()` / `z.ipv6()` | IP address format |
| `string`, `format: date` | `z.iso.date()` | `z.iso.date()` | ISO 8601 date |
| `string`, `format: date-time` | `z.iso.datetime()` | `z.string()` | ISO 8601 date-time |
| `string`, `format: time` | `z.iso.time()` | `z.iso.time()` | ISO 8601 time |
| `object`, `additionalProperties: <schema>` | `z.record(z.string(), schema)` | `z.record(z.string(), schema)` | Dictionary with no fixed properties |
| `object`, `additionalProperties: true` | `z.looseObject(shape)` | `z.looseObject(shape)` | Open/passthrough object allowing extra keys |
| `object`, `propertyNames: <schema>` | `z.record(keySchema, schema)` | `z.record(keySchema, schema)` | Dynamic map with validated key schema (e.g. pattern, format) |
| `object`, `propertyNames: <enum>` | `z.partialRecord(enumSchema, schema)` | `z.partialRecord(enumSchema, schema)` | Closed key schemas use partial record to avoid exhaustiveness |

## Dictionaries, open objects, and key schemas

OpenAPI 3.1 `propertyNames` validates dictionary keys. Open key schemas use `z.record(keySchema, valueSchema)`, including regex, UUID, and length constraints. Closed keys, such as enums, literals, or unions of enums, use `z.partialRecord` so only present keys are validated. This preserves OpenAPI's partial semantics and infers `Partial<Record<Keys, Value>>`.

`patternProperties` combines key regex patterns into an alternation and emits `z.record(z.string().regex(...), valueSchema)`. Zod Mini uses `z.string().check(z.regex(...))` for the key schema.

An `additionalProperties` schema without fixed properties produces a dictionary. With fixed properties, it produces `.catchall(valueSchema)` to preserve that declared shape. `additionalProperties: true` emits `z.looseObject(shape)` to allow undeclared keys.
