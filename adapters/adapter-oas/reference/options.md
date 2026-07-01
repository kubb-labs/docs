---
layout: doc
title: Options
description: Configuration options for @kubb/adapter-oas.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`validate`](#validate) | `boolean` | `true` | Validate the spec before parsing |
| [`contentType`](#contenttype) | `'application/json' \| string` | — | Preferred media type for request and response schemas |
| [`server`](#server) | `{ index?: number, variables?: Record<string, string> }` | — | Which server URL plugins use as the base URL |
| [`discriminator`](#discriminator) | `'preserve' \| 'propagate'` | `'preserve'` | How `discriminator` fields are interpreted |
| [`enums`](#enums) | `'inline' \| 'root'` | `'inline'` | Where inline enums live |
| [`dateType`](#datetype) | `false \| 'string' \| 'stringOffset' \| 'stringLocal' \| 'date'` | `'string'` | How `format: date-time` schemas are represented |
| [`integerType`](#integertype) | `'number' \| 'bigint'` | `'bigint'` | How integers map to TypeScript |
| [`unknownType`](#unknowntype) | `'any' \| 'unknown' \| 'void'` | `'any'` | Type for schemas Kubb cannot infer |
| [`emptySchemaType`](#emptyschematype) | `'any' \| 'unknown' \| 'void'` | `unknownType \| 'any'` | Type for empty schemas |
| [`enumSuffix`](#enumsuffix) | `string` | `'enum'` | Suffix for derived enum names |

### validate

Validates the OpenAPI spec with `@readme/openapi-parser` before parsing. Set it to `false` only when you have a known-invalid spec that you still want to generate from.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |
| Default: | `true`    |

### contentType

Preferred media type when an operation defines several. Operations with multiple media types use this one.

Without a value, it falls back to the first JSON-compatible media type found in the spec (`application/json`, `application/vnd.api+json`, or any `*+json`).

|          |                                |
| -------: | :----------------------------- |
|    Type: | `'application/json' \| string` |

### server

Selects which entry in the spec's `servers` array becomes the base URL, and supplies values for its `{variable}` placeholders. Plugins that need a base URL read it from here (`@kubb/plugin-axios`, `@kubb/plugin-fetch`, `@kubb/plugin-msw`).

`server.index` points at one of the spec's servers. Most projects pick `0` for the primary server and use higher indices for staging or localhost. `server.variables` fills in any `{variable}` placeholders in the selected URL, falling back to each variable's `default` from the spec. Omit `server` to leave `baseURL` undefined.

|          |                                                          |
| -------: | :------------------------------------------------------- |
|    Type: | `{ index?: number, variables?: Record<string, string> }` |

> [!TIP]
> Plugins read `baseURL` from this server unless they override it explicitly.

Server variables substitute into the `{variable}` placeholders in the selected URL. With a spec server of `https://api.{env}.example.com`, setting `server: { index: 0, variables: { env: 'prod' } }` resolves `baseURL` to `https://api.prod.example.com`.

### discriminator

How `discriminator` fields on `oneOf`/`anyOf` schemas are interpreted.

- `'preserve'` (default) keeps child schemas exactly as written. The discriminator narrows types at the call site, but child shapes stay the same.
- `'propagate'` pushes the discriminator property with its literal value into each child schema, so each branch's `type` field is precisely typed.

|          |                             |
| -------: | :-------------------------- |
|    Type: | `'preserve' \| 'propagate'` |
| Default: | `'preserve'`                |

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
        type:
          type: string
        indoor:
          type: boolean
    Dog:
      type: object
      properties:
        type:
          type: string
        name:
          type: string
```

```typescript ['preserve' (default)]
export type Cat = {
  type: string
  indoor?: boolean
}

export type Dog = {
  type: string
  name?: string
}

export type Animal = Cat | Dog
```

```typescript ['propagate']
export type Cat = {
  type: 'cat'
  indoor?: boolean
}

export type Dog = {
  type: 'dog'
  name?: string
}

export type Animal = Cat | Dog
```

:::

### enums

Where inline enums live.

- `'inline'` (default) keeps each enum on the property that declares it.
- `'root'` lifts every inline enum to a reusable top-level schema named after its context (for example `PetStatusEnum`) and references it wherever it appears.

|          |                      |
| -------: | :------------------- |
|    Type: | `'inline' \| 'root'` |
| Default: | `'inline'`           |

::: code-group

```yaml [OpenAPI spec]
openapi: 3.0.3
components:
  schemas:
    Pet:
      type: object
      properties:
        status:
          type: string
          enum: [active, inactive]
```

```typescript ['inline' (default)]
export type Pet = {
  status?: 'active' | 'inactive'
}
```

```typescript ['root']
export type PetStatusEnum = 'active' | 'inactive'

export type Pet = {
  status?: PetStatusEnum
}
```

:::

### dateType

How `format: date-time` schemas are represented downstream.

- `false` falls through to a plain `string` with no validation.
- `'string'` (default) emits an ISO 8601 datetime string.
- `'stringOffset'` emits a datetime string with a timezone offset.
- `'stringLocal'` emits a local datetime string with no timezone.
- `'date'` emits a JavaScript `Date`. Best for client code, though JSON needs parsing to revive it.

|          |                                                                 |
| -------: | :-------------------------------------------------------------- |
|    Type: | `false \| 'string' \| 'stringOffset' \| 'stringLocal' \| 'date'` |
| Default: | `'string'`                                                      |

The string variants all emit `string` at the TypeScript type level. The offset and local distinction surfaces in schema output such as Zod.

::: code-group

```typescript [string variants]
// false, 'string', 'stringOffset', 'stringLocal' → string
type CreatedAt = string
```

```typescript ['date']
// format: date-time → JavaScript Date
type CreatedAt = Date
```

:::

### integerType

How `type: integer` (and `format: int64`) maps to TypeScript.

- `'bigint'` (default) is exact for 64-bit IDs, but `JSON.stringify` and `JSON.parse` cannot round-trip it. Use it only when you handle bigint serialization yourself.
- `'number'` fits most JSON APIs. It loses precision above `Number.MAX_SAFE_INTEGER`.

|          |                        |
| -------: | :--------------------- |
|    Type: | `'number' \| 'bigint'` |
| Default: | `'bigint'`             |

::: code-group

```typescript ['bigint' (default)]
type Pet = {
  id: bigint
}
```

```typescript ['number']
type Pet = {
  id: number
}
```

:::

### unknownType

AST type used when a schema's type cannot be inferred from the spec (`additionalProperties: true`, a missing `type`, and similar).

Pick `'unknown'` to force callers to narrow before using the value. `'any'` is the loosest. `'void'` matches some legacy APIs.

|          |                                |
| -------: | :----------------------------- |
|    Type: | `'any' \| 'unknown' \| 'void'` |
| Default: | `'any'`                        |

::: code-group

```typescript ['any' (default)]
type Pet = {
  extra: any
}
```

```typescript ['unknown']
type Pet = {
  extra: unknown
}
```

```typescript ['void']
type Pet = {
  extra: void
}
```

:::

### emptySchemaType

AST type used for fully empty schemas (`{}`). It follows `unknownType` unless you set it. Override it only when empty schemas should be treated differently from unresolvable ones.

|          |                                |
| -------: | :----------------------------- |
|    Type: | `'any' \| 'unknown' \| 'void'` |
| Default: | `unknownType \| 'any'`         |

> [!TIP]
> A common pairing sets `unknownType: 'unknown'` for safety and `emptySchemaType: 'any'` so empty 204 response bodies stay easy to use.

::: code-group

```typescript ['any' (default)]
// empty schema {} → any
type EmptyModel = any
```

```typescript ['unknown']
// empty schema {} → unknown
type EmptyModel = unknown
```

:::

### enumSuffix

Suffix appended to derived enum names when Kubb has to invent one, typically for inline enums on object properties.

An inline enum on a `status` property becomes `statusEnum` with the default. Change it to align with your project's naming convention.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'enum'` |

::: code-group

```typescript ['enum' (default)]
// Property `status` with inline enum values
const statusEnum = { available: 'available', pending: 'pending' } as const
type StatusEnum = (typeof statusEnum)[keyof typeof statusEnum]
```

```typescript ['type']
const statusType = { available: 'available', pending: 'pending' } as const
type StatusType = (typeof statusType)[keyof typeof statusType]
```

:::
