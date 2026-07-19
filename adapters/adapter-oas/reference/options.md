---
layout: doc
title: Options
description: Configuration options for @kubb/adapter-oas covering spec validation, content type, the server base URL, discriminators, enums, and how OpenAPI types map to TypeScript.
outline: deep
---

# Options

Options for `adapterOas`, with type and default in the table.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`validate`](#validate) | `boolean` | `true` | Validate the spec before parsing |
| [`contentType`](#contenttype) | `'application/json' \| string` | — | Preferred media type for request and response schemas |
| [`server`](#server) | `{ index?: number, variables?: Record<string, string> }` | — | Which spec server Kubb resolves into the document `baseURL` |
| [`discriminator`](#discriminator) | `'preserve' \| 'propagate'` | `'preserve'` | How `discriminator` fields are interpreted |
| [`enums`](#enums) | `'inline' \| 'root'` | `'inline'` | Where inline enums live |
| [`dateType`](#datetype) | `false \| 'string' \| 'stringOffset' \| 'stringLocal' \| 'date'` | `'string'` | How `format: date-time` schemas are represented |
| [`integerType`](#integertype) | `'number' \| 'bigint'` | `'bigint'` | How integers map to TypeScript |
| [`unknownType`](#unknowntype) | `'any' \| 'unknown' \| 'void'` | `'any'` | Type for schemas Kubb cannot infer |
| [`emptySchemaType`](#emptyschematype) | `'any' \| 'unknown' \| 'void'` | `unknownType \| 'any'` | Type for empty schemas |
| [`enumSuffix`](#enumsuffix) | `string` | `'enum'` | Suffix for derived enum names |

### validate

Validates the OpenAPI spec with `@readme/openapi-parser` before parsing. Set it to `false` only when you have a known-invalid spec that you still want to generate from.

### contentType

Preferred media type when an operation defines several. Without a value, Kubb falls back to the first JSON-like media type in the spec (`application/json`, `application/x-json`, `text/json`, `text/x-json`, or any `*+json`), and to the first media type overall when none is JSON-like.

### server

Selects which entry in the spec's `servers` array Kubb resolves into the document `baseURL`, filling in any `{variable}` placeholders. `server.index` points at one of the spec's servers, usually `0` for the primary one. `server.variables` supplies placeholder values, falling back to each variable's `default` from the spec. Omit `server` and `baseURL` resolves to `null`.

The resolved `baseURL` reaches banner functions through `BannerMeta.baseURL` but does not set request URLs on its own. To change where a generated client sends requests, use that plugin's own `baseURL` option ([`@kubb/plugin-fetch`](/plugins/plugin-fetch/), [`@kubb/plugin-axios`](/plugins/plugin-axios/), [`@kubb/plugin-msw`](/plugins/plugin-msw/)).

With a spec server of `https://api.{env}.example.com`, `server: { index: 0, variables: { env: 'prod' } }` resolves `baseURL` to `https://api.prod.example.com`.

### discriminator

How `discriminator` fields on `oneOf`/`anyOf` schemas are interpreted.

- `'preserve'` (default) keeps child schemas exactly as written, though the discriminator still narrows types at the call site.
- `'propagate'` pushes the discriminator property with its literal value into each child schema, so each branch's `type` field is precisely typed.

::: code-group

```yaml [OpenAPI spec]
openapi: 3.0.3
components:
  schemas:
    Animal:
      required: [type]
      type: object
      oneOf:
        - $ref: '#/components/schemas/Cat'
        - $ref: '#/components/schemas/Dog'
      discriminator:
        propertyName: type
        mapping:
          cat: '#/components/schemas/Cat'
          dog: '#/components/schemas/Dog'
    Cat:
      type: object
      properties:
        type: { type: string }
        indoor: { type: boolean }
    Dog:
      type: object
      properties:
        type: { type: string }
        name: { type: string }
```

```typescript ['preserve' (default)]
export type Cat = { type: string; indoor?: boolean }
export type Dog = { type: string; name?: string }
export type Animal = Cat | Dog
```

```typescript ['propagate']
export type Cat = { type: 'cat'; indoor?: boolean }
export type Dog = { type: 'dog'; name?: string }
export type Animal = Cat | Dog
```

:::

### enums

Where inline enums live.

- `'inline'` (default) keeps each enum on the property that declares it.
- `'root'` lifts every inline enum to a reusable top-level schema named after its context (for example `PetStatusEnum`) and references it wherever it appears.

```typescript
// enum [active, inactive] on Pet.status

// 'inline' (default)
export type Pet = { status?: 'active' | 'inactive' }

// 'root'
export type PetStatusEnum = 'active' | 'inactive'
export type Pet = { status?: PetStatusEnum }
```

### dateType

How `format: date-time` schemas are represented downstream.

- `false` falls through to a plain `string` with no validation.
- `'string'` (default) emits an ISO 8601 datetime string.
- `'stringOffset'` emits a datetime string with a timezone offset.
- `'stringLocal'` emits a local datetime string with no timezone.
- `'date'` emits a JavaScript `Date`, best for client code, though JSON needs parsing to revive it.

The string variants all emit `string` at the TypeScript type level. The offset and local distinction surfaces in schema output such as Zod.

### integerType

How `type: integer` (and `format: int64`) maps to TypeScript.

- `'bigint'` (default) is exact for 64-bit IDs, but `JSON.stringify` and `JSON.parse` cannot round-trip it. Use it only when you handle bigint serialization yourself.
- `'number'` fits most JSON APIs. It loses precision above `Number.MAX_SAFE_INTEGER`.

### unknownType

AST type used when a schema's type cannot be inferred from the spec (`additionalProperties: true`, a missing `type`, and similar). Pick `'unknown'` to force callers to narrow before using the value, `'any'` for the loosest option, or `'void'` to match some legacy APIs.

### emptySchemaType

AST type used for fully empty schemas (`{}`). It follows `unknownType` unless you set it. Override it only when empty schemas should be treated differently from unresolvable ones.

> [!TIP]
> A common pairing sets `unknownType: 'unknown'` for safety and `emptySchemaType: 'any'` so empty 204 response bodies stay easy to use.

### enumSuffix

Suffix appended to derived enum names when Kubb has to invent one, typically for inline enums on object properties. The derived name joins the parent schema name, the property name, and the suffix in PascalCase, so an inline enum on the `status` property of the `Pet` schema derives `PetStatusEnum`. Set it to `'type'` and the same enum derives `PetStatusType`.
