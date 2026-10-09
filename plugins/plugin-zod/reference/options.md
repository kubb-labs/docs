---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-zod.
outline: deep
---

# Options

Pass these options to `pluginZod()`. Shared options link to [Shared plugin options](/docs/5.x/reference/plugin-options), which documents their behavior once.

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`output`](/docs/5.x/reference/plugin-options#output) | Where the generated files are written and exported. | `{ path: 'zod', barrel: { type: 'named' } }` |
| ↳ [`output.path`](/docs/5.x/reference/plugin-options#output-path) | Choose the output folder or file. | `'zod'` |
| ↳ [`output.mode`](/docs/5.x/reference/plugin-options#output-mode) | Write a single file or a directory of files. | Inferred from `output.path` |
| ↳ [`output.barrel`](/docs/5.x/reference/plugin-options#output-barrel) | Configure barrel exports. | `{ type: 'named' }` |
| ↳ [`output.banner`](/docs/5.x/reference/plugin-options#output-banner) | Add content before generated code. | None |
| ↳ [`output.footer`](/docs/5.x/reference/plugin-options#output-footer) | Add content after generated code. | None |
| [`group`](/docs/5.x/reference/plugin-options#group) | Split output into per-tag or per-path folders. | None |
| ↳ [`group.type`](/docs/5.x/reference/plugin-options#group-type) | Group operations by tag or URL path. | Required with `group` |
| ↳ [`group.name`](/docs/5.x/reference/plugin-options#group-name) | Customize output group names. | camelCased tag or raw path segment |
| [`importPath`](#importpath) | Module the generated files import `z` from. | `'zod'`, or `'zod/mini'` with `mini` |
| [`inferred`](#inferred) | Emit a `z.infer` alias next to each schema. | `false` |
| [`coercion`](#coercion) | Coerce input before validation. | `false` |
| ↳ [`coercion.dates`](#coercion) | Coerce Date-typed fields before validation. | `false` |
| ↳ [`coercion.strings`](#coercion) | Coerce strings before validation. | `false` |
| ↳ [`coercion.numbers`](#coercion) | Coerce numbers before validation. | `false` |
| [`guidType`](#guidtype) | Validator for `format: uuid` properties. | `'uuid'` |
| [`regexType`](#regextype) | How an OpenAPI `pattern` is written. | `'literal'` |
| [`compile`](#compile) | Wrap schemas in `z.compile` for fast-path validation. | `false` |
| ↳ [`compile.strict`](#compile) | Require schemas to compile without interpreter fallback. | `false` |
| [`mini`](#mini) | Generate Zod Mini schemas. | `false` |
| [`typeGuards`](#typeguards) | Generate `is*` type guards and `assert*` assertions. | `false` |
| ↳ [`typeGuards.is`](#typeguards) | Generate type guard functions. | `false` |
| ↳ [`typeGuards.assert`](#typeguards) | Generate assertion functions. | `false` |
| [`include`](/docs/5.x/reference/plugin-options#include) | Keep only operations and schemas that match. | None |
| [`exclude`](/docs/5.x/reference/plugin-options#exclude) | Skip operations and schemas that match. | `[]` |
| [`override`](/docs/5.x/reference/plugin-options#override) | Apply different options per pattern. | `[]` |
| [`resolver`](#resolver) | Customize generated names and file paths. | `resolverZod` |
| [`macros`](/docs/5.x/reference/plugin-options#macros) | Rewrite AST nodes before printing. | `[]` |
| [`printer`](#printer) | Replace the handler for a schema type. | None |
| ↳ [`printer.nodes`](#printer) | Customize handlers for schema node types. | None |

## Option details

### importPath

Module specifier for the `import { z } from '...'` statement in every generated file, so you can re-export Zod from your own module.

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

Wraps schemas in `z.coerce` so input is coerced before validation, for form data, query params, and similar string sources. See [Coercion for primitives](https://zod.dev/?id=coercion-for-primitives).

| | |
| --- | --- |
| Type | `boolean \| { dates?: boolean, strings?: boolean, numbers?: boolean }` |
| Required | `false` |
| Default | `false` |

::field-group

:::field{name="false"}
Default value. Coerces nothing and validates strictly.
:::

:::field{name="true"}
Coerces strings, numbers, and dates with `z.coerce.string()`, `z.coerce.number()` and `z.coerce.date()`.
:::

:::field{name="{ dates?, strings?, numbers? }"}
Chooses which primitives to coerce.
:::

::

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

::field-group

:::field{name="'uuid'"}
Default value. Generates `z.uuid()`, a standard RFC 4122 UUID.
:::

:::field{name="'guid'"}
Generates `z.guid()`, which is looser and accepts Microsoft-style GUIDs.
:::

::

### regexType

Controls how an OpenAPI `pattern` is written inside `.regex(...)`. Use `'constructor'` when a regex literal breaks your build or you need a string pattern.

| | |
| --- | --- |
| Type | `'literal' \| 'constructor'` |
| Required | `false` |
| Default | `'literal'` |

::field-group

:::field{name="'literal'"}
Default value. Emits a regex literal, such as `.regex(/^[a-z]+$/)`.
:::

:::field{name="'constructor'"}
Emits the `RegExp` constructor, such as `.regex(new RegExp('^[a-z]+$'))`.
:::

::

### compile

Wraps schemas in `z.compile(...)` to generate validation code instead of interpreting the schema on each call.

| | |
| --- | --- |
| Type | `boolean \| { strict?: boolean }` |
| Required | `false` |
| Default | `false` |

::field-group

:::field{name="false"}
Default value. Leaves schemas uncompiled.
:::

:::field{name="true"}
Compiles schemas using `z.compile(...)`.
:::

:::field{name="{ strict: true }"}
Passes `{ strict: true }` to `z.compile(...)`, which throws when any part of the schema cannot be compiled into flat JavaScript instead of falling back to the interpreter.
:::

::

> [!NOTE]
> `compile` requires Zod v4.5.0 or higher. Schemas with circular references (`z.lazy`) and bare `$ref` response aliases are kept uncompiled to prevent runtime errors.

```typescript [compile: { strict: true }]
import * as z from 'zod'

export const petSchema = z.compile(
  z.object({
    id: z.number(),
    name: z.string(),
  }),
  { strict: true }, // omitted with compile: true
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

Generates TypeScript type guards (`is*`) and assertion functions (`assert*`) for schemas using Zod v4's native `validate` API.

| | |
| --- | --- |
| Type | `boolean \| { is?: boolean, assert?: boolean }` |
| Required | `false` |
| Default | `false` |

> [!IMPORTANT]
> The generated type guards and assertions require Zod v4.6.0 or higher.

::field-group

:::field{name="false"}
Default value. Generates only the Zod schemas.
:::

:::field{name="true"}
Generates both `is<Schema>` type guards and `assert<Schema>` assertion functions.
:::

:::field{name="{ is?: boolean; assert?: boolean }"}
Enables type guards or assertions separately.
:::

::

When [`inferred`](#inferred) is `true`, the guards narrow to the generated type alias such as `PetSchemaType`. When [`mini`](#mini) is `true`, they route through `z.validate` and `z.parse`.

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

::code-collapse{name="Generated petSchema.ts with typeGuards: true"}

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

::

### resolver

Overrides generated file and symbol names. Omitted members keep `resolverZod`. The shared members (`name`, `file`, `imports`) and the `this` context are described under [`resolver`](/docs/5.x/reference/plugin-options#resolver).

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverZod>` |
| Required | `false` |

::code-collapse{name="ResolverZod patch members"}

```typescript [Partial override]
type ResolverZodPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  imports?(options: ResolveImportsOptions): Array<ImportNode>
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

::

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
