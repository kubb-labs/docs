---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-zod.
outline: deep
---

# Options

Options for `pluginZod`.

## Options overview

Select an option to see its type, default, and examples. Nested settings link to their own section or the parent option.

| Option | Purpose |
| --- | --- |
| [`output`](#output) | Where the generated files are written and exported. |
| ↳ [`output.path`](#output-path) | Choose the output folder or file. |
| ↳ [`output.mode`](#output-mode) | Write a single file or a directory of files. |
| ↳ [`output.barrel`](#output-barrel) | Configure barrel exports. |
| ↳ [`output.barrel.type`](#output-barrel) | Use named exports or wildcard exports. |
| ↳ [`output.barrel.nested`](#output-barrel) | Choose whether barrels reference subdirectory barrels. |
| ↳ [`output.banner`](#output-banner) | Add content before generated code. |
| ↳ [`output.footer`](#output-footer) | Add content after generated code. |
| [`group`](#group) | Split output into per-tag or per-path folders. |
| ↳ [`group.type`](#group-type) | Group operations by tag or URL path. |
| ↳ [`group.name`](#group-name) | Customize output group names. |
| [`importPath`](#importpath) | Module the generated files import `z` from. |
| [`inferred`](#inferred) | Emit a `z.infer` alias next to each schema. |
| [`coercion`](#coercion) | Coerce input before validation. |
| ↳ [`coercion.dates`](#coercion) | Coerce Date-typed fields before validation. |
| ↳ [`coercion.strings`](#coercion) | Coerce strings before validation. |
| ↳ [`coercion.numbers`](#coercion) | Coerce numbers before validation. |
| [`guidType`](#guidtype) | Validator for `format: uuid` properties. |
| [`regexType`](#regextype) | How an OpenAPI `pattern` is written. |
| [`compile`](#compile) | Wrap schemas in `z.compile` for fast-path validation. |
| ↳ [`compile.strict`](#compile) | Require schemas to compile without interpreter fallback. |
| [`mini`](#mini) | Generate Zod Mini schemas. |
| [`typeGuards`](#typeguards) | Generate `is*` type guards and `assert*` assertions. |
| ↳ [`typeGuards.is`](#typeguards) | Generate type guard functions. |
| ↳ [`typeGuards.assert`](#typeguards) | Generate assertion functions. |
| [`include`](#include) | Keep only operations that match. |
| [`exclude`](#exclude) | Skip operations that match. |
| [`override`](#override) | Apply different options per pattern. |
| [`resolver`](#resolver) | Customize generated names and file paths. |
| [`macros`](#macros) | Rewrite AST nodes before printing. |
| [`printer`](#printer) | Replace the handler for a schema type. |
| ↳ [`printer.nodes`](#printer) | Customize handlers for schema node types. |

## Option details

### output

Where the generated `.ts` files are written and how they are exported.

| | |
| --- | --- |
| Type | `Output` |
| Required | `false` |
| Default | `{ path: 'zod', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`. For a single file, set `output.mode: 'file'` and give `path` an extension, such as `'zod.ts'`.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `'zod'` |

#### output.mode

How the plugin consolidates generated code into files.

- `'file'` writes everything into a single file, so `output.path` must include the file extension (for example `'zod.ts'`).
- `'directory'` writes one file per operation or schema under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

| | |
| --- | --- |
| Type | `'directory' \| 'file'` |
| Required | `false` |
| Default | follows the shape of `output.path` |

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

Split output into per-tag or per-path folders.

| | |
| --- | --- |
| Type | `Group` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function that turns a group key (first tag or path segment) into a folder or identifier name, used as the subdirectory under `output.path` and a suffix for aggregate files. For `type: 'path'`, the default keeps the URL segment as-is instead of camelCasing.

| | |
| --- | --- |
| Type | `(context: { group: string }) => string` |
| Required | `false` |
| Default | `'tag'`: `({ group }) => camelCase(group)`; `'path'`: the raw URL segment, uncased |

### importPath

Module specifier for the `import { z } from '...'` statement in every generated file, so you can re-export Zod from your own module. Defaults to `'zod'`, or `'zod/mini'` when `mini` is on.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `mini ? 'zod/mini' : 'zod'` |

> [!NOTE]
> `'zod'` and `'zod/mini'` import the `z` namespace (`import * as z`), but a custom module imports the named `z` export (`import { z }`), so re-export `z` from there.

### inferred

Exports a `z.infer<typeof schema>` type alias next to every generated schema, so the schema is the single source of truth and you do not import types from `@kubb/plugin-ts`. The alias is the PascalCased schema name with a `SchemaType` suffix, so `petSchema` becomes `PetSchemaType`.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `false` |

```typescript
import * as z from 'zod'

export const petSchema = z.object({
  name: z.string(),
})

export type PetSchemaType = z.infer<typeof petSchema>
```

It also generates a `ResponsesSchema` per operation, the per-status responses record, with its inferred type. [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and [`@kubb/plugin-axios`](/plugins/plugin-axios/) key their `RequestResult` on it when `@kubb/plugin-ts` is absent.

### coercion

Wraps schemas in `z.coerce` so input is coerced before validation, for form data, query params, and similar string sources.

| | |
| --- | --- |
| Type | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` |
| Required | `false` |
| Default | `false` |

- `true` coerces strings, numbers, and dates.
- `false` (default) coerces nothing and validates strictly.
- An object picks which primitives to coerce.

See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

```typescript
z.coerce.string()
z.coerce.number()
z.coerce.date()
```

> [!NOTE]
> `dates` coerces only `Date`-typed fields (from `dateType: 'date'`). Fields kept as ISO strings (`z.iso.date()`, `z.iso.datetime()`) are never coerced.
>
> `format: time` fields are never coerced either, because `new Date()` cannot parse a bare `HH:mm:ss`. With `dateType.time: 'date'`, a time decodes into a `Date` on `1970-01-01` UTC and encodes back to `HH:mm:ss` (fractional seconds are dropped). For a real time-of-day type such as `Temporal.PlainTime`, see [Encode a custom type on requests](/plugins/plugin-zod/guide/customization#encode-custom-types).

### guidType

Validator used for OpenAPI properties with `format: uuid`.

| | |
| --- | --- |
| Type | `'uuid' \| 'guid'` |
| Required | `false` |
| Default | `'uuid'` |

- `'uuid'` (default) generates `z.uuid()`, a standard RFC 4122 UUID.
- `'guid'` generates `z.guid()`, which is looser and accepts Microsoft-style GUIDs.

### regexType

Controls how an OpenAPI `pattern` is written inside `.regex(...)`.

| | |
| --- | --- |
| Type | `'literal' \| 'constructor'` |
| Required | `false` |
| Default | `'literal'` |

- `'literal'` (default) emits a regex literal, such as `.regex(/^[a-z]+$/)`.
- `'constructor'` emits the `RegExp` constructor, such as `.regex(new RegExp('^[a-z]+$'))`.

Use `'constructor'` when a regex literal breaks your build or you need a string pattern.

### compile

Wraps schemas in `z.compile(...)` to generate validation code instead of interpreting the schema on each call.

| | |
| --- | --- |
| Type | `boolean \| { strict?: boolean }` |
| Required | `false` |
| Default | `false` |

- `true` compiles schemas using `z.compile(...)`.
- `false` (default) leaves schemas uncompiled.
- `{ strict: true }` passes `{ strict: true }` to `z.compile(...)`, which throws an error if any part of the schema cannot be compiled into flat JavaScript, preventing silent fallback to the interpreter.

> [!NOTE]
> `compile` requires **Zod v4.5.0 or higher**. Schemas with circular references (`z.lazy`) and bare `$ref` response aliases are automatically kept uncompiled to prevent runtime errors.

```typescript
import * as z from 'zod'

export const petSchema = z.compile(
  z.object({
    id: z.number(),
    name: z.string(),
  }),
)
```

With `{ strict: true }`:

```typescript
import * as z from 'zod'

export const petSchema = z.compile(
  z.object({
    id: z.number(),
    name: z.string(),
  }),
  { strict: true },
)
```

### mini

Switches code generation to [Zod Mini](https://zod.dev/packages/mini), which uses the functional API (`z.optional(z.string())`) instead of the chainable one (`z.string().optional()`) so bundlers can tree-shake unused validators. `mini: true` also defaults `importPath` to `'zod/mini'`.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `false` |

```typescript
import * as z from 'zod/mini'

z.optional(z.string())
z.nullable(z.number())
z.array(z.string()).check(z.minLength(1), z.maxLength(10))
```

### typeGuards

> [!IMPORTANT]
> The generated type guards and assertions require Zod v4.6.0 or higher.

| | |
| --- | --- |
| Type | `boolean \| { is?: boolean, assert?: boolean }` |
| Required | `false` |
| Default | `false` |

Generates TypeScript type guards (`is*`) and assertion functions (`assert*`) for schemas using Zod v4's native `validate` API.

- `true`: Generates both `is<Schema>` type guards and `assert<Schema>` assertion functions.
- `{ is?: boolean; assert?: boolean }`: Selectively enables type guards or assertions.
- `false` (default): Generates only the Zod schemas.

```typescript
pluginZod({
  typeGuards: true,
})
```

Emitted code:

```typescript [src/gen/zod/petSchema.ts]
import * as z from 'zod'

export const petSchema = z.object({
  id: z.int32(),
  name: z.string(),
})

export const isPet = (data: unknown): data is z.infer<typeof petSchema> => petSchema.validate(data)

export function assertPet(data: unknown): asserts data is z.infer<typeof petSchema> {
  if (!petSchema.validate(data)) {
    petSchema.parse(data)
  }
}
```

When [`inferred`](#inferred) is `true`, the guards narrow to the generated schema type alias (e.g. `PetSchemaType`). When [`mini`](#mini) is `true`, they route through `z.validate` and `z.parse`.

Use the generated guard to filter unknown data, or assert a value before reading it:

```typescript [usage.ts]
import { isPet, assertPet } from './src/gen/zod/petSchema'

const items: unknown[] = []
const pets = items.filter(isPet)

export function processPayload(payload: unknown) {
  assertPet(payload)
  console.log(payload.name)
}
```

### include

Keep only operations that match.

| | |
| --- | --- |
| Type | `Array<Include>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

Skip operations that match.

| | |
| --- | --- |
| Type | `Array<Exclude>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

Apply different options per pattern.

| | |
| --- | --- |
| Type | `Array<Override>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/override.md-->

For example, `override: [{ type: 'tag', pattern: 'user', options: { coercion: true } }]` coerces input only for the `user` tag.

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverZod>` |
| Required | `false` |

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverZodPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  schema?: {
    typeName?(name: string): string       // → 'PetSchemaType'
    type?(name: string): string           // → 'PetSchemaType'
    inputName?(name: string): string      // → 'orderInputSchema'
    inputTypeName?(name: string): string  // → 'OrderInputSchemaType'
    isName?(name: string): string         // → 'isPet'
    assertName?(name: string): string     // → 'assertPet'
  }
  param?: {
    name?(node: OperationNode, param: ParameterNode): string    // → 'deletePetPathPetIdSchema'
    path?(node: OperationNode, param: ParameterNode): string     // → 'deletePetPathSchema'
    query?(node: OperationNode, param: ParameterNode): string    // → 'findPetsByStatusQuerySchema'
    headers?(node: OperationNode, param: ParameterNode): string  // → 'deletePetHeadersSchema'
  }
  response?: {
    status?(node: OperationNode, statusCode: StatusCode): string // → 'listPetsStatus200Schema'
    body?(node: OperationNode): string                           // → 'createPetBodySchema'
    responses?(node: OperationNode): string                      // → 'listPetsResponsesSchema'
    response?(node: OperationNode): string                       // → 'listPetsResponseSchema'
    error?(node: OperationNode): string                          // → 'listPetsErrorSchema'
    options?(node: OperationNode): string                        // → 'ListPetsOptionsSchemaType'
  }
}
```

### macros

Rewrite AST nodes before printing.

| | |
| --- | --- |
| Type | `Array<Macro>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/macros-option.md-->

### printer

Replaces the Zod handler for a schema type such as `'integer'` or `'string'`, each returning the Zod expression as a string and targeting the Zod Mini printer when `mini: true`. Inside a handler, `this.base(node)` returns the built-in output to wrap and `this.transform(node)` recurses into nested nodes. See the [printer guide](/docs/5.x/how-to/printers).

| | |
| --- | --- |
| Type | `{ nodes?: PrinterZodNodes \| PrinterZodMiniNodes }` |
| Required | `false` |

```typescript twoslash
import { pluginZod } from '@kubb/plugin-zod'

pluginZod({
  printer: {
    nodes: {
      integer() {
        return 'z.number()'
      },
      date() {
        return 'z.string().date()'
      },
    },
  },
})
```

A handler that reads `this.options.direction` (`'decode'` for responses, `'encode'` for request bodies and parameters) and returns a different expression per direction registers a two-way conversion: the generator detects the difference and emits an `${name}InputSchema` variant for request bodies to resolve to, including through a `$ref`. See [Encode a custom type on requests](/plugins/plugin-zod/guide/customization#encode-custom-types).

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
