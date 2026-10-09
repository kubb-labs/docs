---
layout: doc
title: Options
description: Configuration options for @kubb/adapter-oas covering spec
  validation, content type, the server base URL, discriminators, enums, and how
  OpenAPI types map to TypeScript.
outline: deep
---

# Options

All `adapterOas` options are optional. Types and defaults are listed below.

::field-group

:::field{name="validate" type="boolean"}
Validate the spec before parsing. [See details](#validate).

Default: `true`.
:::

:::field{name="contentType" type="'application/json' | string"}
Preferred media type for request and response schemas. [See details](#contenttype).

No default.
:::

:::field{name="server" type="{ index?: number, variables?: Record<string, string> }"}
Which spec server Kubb resolves into the document `baseURL`. [See details](#server).

No default.
:::

:::field{name="discriminator" type="'preserve' | 'propagate'"}
How `discriminator` fields are interpreted. [See details](#discriminator).

Default: `'preserve'`.
:::

:::field{name="enums" type="'inline' | 'root'"}
Where inline enums live. [See details](#enums).

Default: `'inline'`.
:::

:::field{name="dateType" type="false | 'string' | 'stringOffset' | 'stringLocal' | 'date' | { dateTime?, date?, time? }"}
How `date-time`, `date`, and `time` schemas are represented. [See details](#datetype).

Default: `'string'`.
:::

:::field{name="integerType" type="'number' | 'bigint'"}
How integers map to TypeScript. [See details](#integertype).

Default: `'bigint'`.
:::

:::field{name="unknownType" type="'any' | 'unknown' | 'void'"}
Type for schemas Kubb cannot infer. [See details](#unknowntype).

Default: `'unknown'`.
:::

:::field{name="emptySchemaType" type="'any' | 'unknown' | 'void'"}
Type for empty schemas. [See details](#emptyschematype).

Default: `unknownType` (`'unknown'` by default).
:::

:::field{name="enumSuffix" type="string"}
Suffix for derived enum names. [See details](#enumsuffix).

Default: `'enum'`.
:::

::

### validate

Validates the OpenAPI spec with `@readme/openapi-parser` before parsing. Each problem is reported as a [`KUBB_INVALID_SPEC`](/docs/5.x/reference/diagnostics#kubb-invalid-spec) warning, and generation continues. Set it to `false` to skip the check, which makes generation faster on a large spec. Run [`kubb validate`](/docs/5.x/reference/commands/validate) to list every error.

### contentType

Preferred media type when an operation defines several. Without a value, Kubb falls back to the first JSON-like media type in the spec (`application/json`, `application/x-json`, `text/json`, `text/x-json`, or any `*+json`), and to the first media type overall when none is JSON-like.

### server

Selects which entry in the spec's `servers` array Kubb resolves into the document `baseURL`, filling in any `{variable}` placeholders. `server.index` points at one of the spec's servers, usually `0` for the primary one. `server.variables` supplies placeholder values, falling back to each variable's `default` from the spec. Omit `server` and `baseURL` resolves to `null`.

The resolved `baseURL` reaches banner functions through `BannerMeta.baseURL` but does not set request URLs on its own. To change where a generated client sends requests, use that plugin's own `baseURL` option ([`@kubb/plugin-fetch`](/plugins/plugin-fetch/), [`@kubb/plugin-axios`](/plugins/plugin-axios/), [`@kubb/plugin-msw`](/plugins/plugin-msw/)).

With a spec server of `https://api.{env}.example.com`, `server: { index: 0, variables: { env: 'prod' } }` resolves `baseURL` to `https://api.prod.example.com`.

### discriminator

How `discriminator` fields on `oneOf`/`anyOf` schemas are interpreted.

| Value | Behavior |
| --- | --- |
| `'preserve'` (default) | Keeps child schemas exactly as written, though the discriminator still narrows types at the call site. |
| `'propagate'` | Pushes the discriminator property with its literal value into each child schema, so each branch's `type` field is precisely typed. |

::code-group

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

::

### enums

Where inline enums live.

| Value | Behavior |
| --- | --- |
| `'inline'` (default) | Keeps each enum on the property that declares it. |
| `'root'` | Lifts every inline enum to a reusable top-level schema named after its context (for example `PetStatusEnum`) and references it wherever it appears. |

For an enum with values `active` and `inactive` on `Pet.status`:

::code-group

```typescript ['inline' (default)]
export type Pet = { status?: 'active' | 'inactive' }
```

```typescript ['root']
export type PetStatusEnum = 'active' | 'inactive'
export type Pet = { status?: PetStatusEnum }
```

::

### dateType

How `date-time`, `date`, and `time` schemas are represented downstream.

Pass a single value to apply it to all three formats:

| Value | Representation |
| --- | --- |
| `false` | A plain `string` with no validation. |
| `'string'` (default) | An ISO 8601 string. |
| `'stringOffset'` | A datetime string with a timezone offset. `date-time` only; `date` and `time` fall back to `'string'`. |
| `'stringLocal'` | A local datetime string with no timezone. `date-time` only; `date` and `time` fall back to `'string'`. |
| `'date'` | A JavaScript `Date`, best for client code, though JSON needs parsing to revive it. |

The string variants all emit `string` at the TypeScript type level. The offset and local distinction surfaces in schema output such as Zod.

Pass an object to set `dateTime`, `date`, and `time` independently. A key you leave out defaults to `'string'`, regardless of the other keys.

```ts
adapterOas({
  dateType: {
    dateTime: 'date', // Date object for timestamps
    date: 'string', // plain string for date-only values, since Date can't represent them safely
    time: 'string',
  },
})
```

### integerType

How `type: integer` (and `format: int64`) maps to TypeScript.

- `'bigint'` (default) is exact for 64-bit IDs, but `JSON.stringify` and `JSON.parse` cannot round-trip it. Use it only when you handle bigint serialization yourself.
- `'number'` fits most JSON APIs. It loses precision above `Number.MAX_SAFE_INTEGER`.

This option only applies to schemas that declare a numeric type. A schema that declares `type: string` stays a `string` whatever its format, so the `{ type: 'string', format: 'int64' }` that gRPC-gateway and other [ProtoJSON](https://protobuf.dev/programming-guides/json/#int64-strings) producers emit generates a `string`. `@kubb/plugin-zod` validates those fields with a digits `.regex(...)` and `@kubb/plugin-faker` mocks them with a numeric string.

### unknownType

AST type used when a schema's type cannot be inferred from the spec (`additionalProperties: true`, a missing `type`, and similar). Pick `'unknown'` to force callers to narrow before using the value, `'any'` for the loosest option, or `'void'` to match some legacy APIs.

### emptySchemaType

AST type used for fully empty schemas (`{}`). It follows `unknownType` unless you set it. Override it only when empty schemas should be treated differently from unresolvable ones.

> [!TIP]
> A common pairing sets `unknownType: 'unknown'` for safety and `emptySchemaType: 'any'` so empty 204 response bodies stay easy to use.

### enumSuffix

Suffix appended to derived enum names when Kubb has to invent one, typically for inline enums on object properties. The derived name joins the parent schema name, the property name, and the suffix in PascalCase, so an inline enum on the `status` property of the `Pet` schema derives `PetStatusEnum`. Set it to `'type'` and the same enum derives `PetStatusType`.
