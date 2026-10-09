---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-faker.
outline: deep
---

# Options

Configure `@kubb/plugin-faker` by passing these options to `pluginFaker()`, all of them optional.

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
| [`typeMode`](#typemode) | Type object and intersection factories from generated values or the declared model. |
| [`dateParser`](#dateparser) | Library that formats string date and time fields. |
| [`regexGenerator`](#regexgenerator) | Library that turns a regex `pattern` into a string. |
| [`locale`](#locale) | Faker locale code for the generated values. |
| [`seed`](#seed) | Value passed to `faker.seed(...)` for deterministic output. |
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
| Default | `{ path: 'mocks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`, and defaulting to `'mocks'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mocks.ts'`.

#### output.mode

How the plugin consolidates generated code. `'file'` writes everything into a single file, where `output.path` must include the extension such as `'mocks.ts'`. `'directory'` writes one file per operation or schema under `output.path`. Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

> [!IMPORTANT]
> `group` requires directory output. Kubb infers the mode from `output.path`. Set `mode: 'directory'` to override that inference. Combining `group` with `mode: 'file'` stops generation with `KUBB_INVALID_PLUGIN_OPTIONS`.

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

Function `(context: { group: string }) => string` that turns a group key into the subdirectory name and the suffix for aggregate files. It defaults to `camelCase(group)` for tag groups, and for `type: 'path'` groups uses the path segment as-is.

### typeMode

Controls the input and return types of object and intersection factories. The default `'inferred'` mode derives the return type from generated values and supplied overrides. Generated optional or nullable fields keep their concrete value types, and overrides preserve literal types.

| | |
| --- | --- |
| Type | `'inferred' \| 'schema'` |
| Required | `false` |
| Default | `'inferred'` |

```typescript [Inferred mode (default)]
pluginFaker({ typeMode: 'inferred' })

// Generated signature:
// export function createOrder<TData extends Partial<Order> = object>(data?: TData)
const order = createOrder({ quantity: 2, complete: true })
const complete: true = order.complete

// TypeScript error: false is not assignable to true.
order.complete = false
```

Use `'schema'` for object and intersection fixtures you modify after creation. Their factories accept `Partial<Model>` and return the declared model type, including its optional and nullable fields.

```typescript [Schema mode]
pluginFaker({ typeMode: 'schema' })

// Generated signature:
// export function createOrder(data?: Partial<Order>): Order
const order = createOrder({ quantity: 2, complete: true })
order.complete = false
order.complete = true

// TypeScript error: foo does not exist in Partial<Order>.
createOrder({ quantity: 2, foo: '' })
```

Object and intersection factories generate the same values in both modes and apply overrides with a shallow merge.

Use [`override`](#override) to select a mode for matching schemas or operations. String patterns are regular expressions, so `^Order$` matches only the `Order` schema. For example, generate mutable `Order` fixtures while keeping the default inferred mode for other schemas:

```typescript [Per-schema mode]
pluginFaker({
  override: [
    {
      type: 'schemaName',
      pattern: '^Order$',
      options: { typeMode: 'schema' },
    },
  ],
})
```

### dateParser

Library used to format `date` and `time` fields represented as strings. Pick a value other than `'faker'` when your project already uses a date library. Any library exporting a default function works, and Kubb adds the import for you.

| | |
| --- | --- |
| Type | `'faker' \| 'dayjs' \| 'moment' \| string` |
| Required | `false` |
| Default | `'faker'` |

A string `date` field renders differently per parser:

::code-group

```typescript ['faker' (default)]
faker.date.anytime().toISOString().substring(0, 10)
```

```typescript ['dayjs']
dayjs(faker.date.anytime()).format('YYYY-MM-DD')
```

```typescript ['moment']
moment(faker.date.anytime()).format('YYYY-MM-DD')
```

::

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ dateParser: 'dayjs' })
```

Install `dayjs` in the consuming app. Generated `date` and `time` strings use `YYYY-MM-DD` and `HH:mm:ss`. `date-time` values keep the ISO string.

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` keyword in the spec. The default `'faker'` emits `faker.helpers.fromRegExp(pattern)` and needs no extra dependency. `'randexp'` emits `new RandExp(pattern).gen()`, which supports a wider regex grammar but adds the `randexp` runtime dependency.

| | |
| --- | --- |
| Type | `'faker' \| 'randexp'` |
| Required | `false` |
| Default | `'faker'` |

### locale

Faker locale code. It switches the named import to `fakerXX` from `@faker-js/faker`, so generated values reflect the target region. The default `'en'` imports `fakerEN`, `'de'` imports `fakerDE`, and `'de_AT'` imports `fakerDE_AT`. See [Faker.js localization](https://fakerjs.dev/api/localization.html) for all locale codes.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `'en'` |

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ locale: 'de' })
```

### seed

Value passed to `faker.seed(...)` and emitted at the top of each generated factory, giving deterministic output across runs for snapshot tests and reproducible local data. Pass a single number or an array of numbers.

| | |
| --- | --- |
| Type | `number \| number[]` |
| Required | `false` |

```typescript [kubb.config.ts]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({ seed: [100] })
```

Factories still accept overrides, such as `createPet({ name: 'Rex' })`.

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

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverFaker>` |
| Required | `false` |

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverFakerPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  param?: {
    name?(node: OperationNode, param: ParameterNode): string    // → 'showPetByIdPathPetId'
    path?(node: OperationNode, param: ParameterNode): string     // → 'createShowPetByIdPath'
    query?(node: OperationNode, param: ParameterNode): string    // → 'createListPetsQuery'
    headers?(node: OperationNode, param: ParameterNode): string  // → 'createDeletePetHeaders'
  }
  response?: {
    status?(node: OperationNode, statusCode: StatusCode): string // → 'listPetsStatus200'
    body?(node: OperationNode): string                           // → 'createPetsBody'
    response?(node: OperationNode): string                       // → 'listPetsResponse'
    responses?(node: OperationNode): string                      // → 'listPetsResponses'
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

Replaces the Faker node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/how-to/printers) covers how overrides compose with macros.

| | |
| --- | --- |
| Type | `{ nodes?: PrinterFakerNodes }` |
| Required | `false` |

```typescript twoslash [Map integer schemas to a float]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  printer: {
    nodes: {
      integer() {
        return 'faker.number.float()'
      },
    },
  },
})
```
