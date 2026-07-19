---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-faker.
outline: deep
---

# Options

Configure `@kubb/plugin-faker` by passing these options to `pluginFaker()`, all of them optional.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'mocks' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`dateParser`](#dateparser) | `'faker' \| 'dayjs' \| 'moment' \| string` | `'faker'` | Library that formats string date and time fields |
| [`regexGenerator`](#regexgenerator) | `'faker' \| 'randexp'` | `'faker'` | Library that turns a regex `pattern` into a string |
| [`locale`](#locale) | `string` | `'en'` | Faker locale code for the generated values |
| [`seed`](#seed) | `number \| number[]` | — | Value passed to `faker.seed(...)` for deterministic output |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverFaker>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |
| [`printer`](#printer) | `{ nodes?: PrinterFakerNodes }` | — | Replace the handler for a schema type |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`, and defaulting to `'mocks'`. To write everything to one file, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mocks.ts'`.

#### output.mode

How the plugin consolidates generated code. `'file'` (the default) writes everything into a single file, where `output.path` must include the extension such as `'mocks.ts'`. `'directory'` writes one file per operation or schema under `output.path`.

> [!IMPORTANT]
> `group` requires `mode: 'directory'`. Pairing `group` with `mode: 'file'` (or leaving `mode` unset) is invalid and fails with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Function `(context: { group: string }) => string` that turns a group key into the subdirectory name and the suffix for aggregate files. It defaults to `camelCase(group)` for tag groups, and for `type: 'path'` groups uses the path segment as-is.

### dateParser

Library used to format `date` and `time` fields represented as strings. Pick a value other than `'faker'` when your project already uses a date library. Any library exporting a default function works, and Kubb adds the import for you.

A string `date` field renders differently per parser:

::: code-group

```typescript ['faker' (default)]
faker.date.anytime().toISOString().substring(0, 10)
```

```typescript ['dayjs']
dayjs(faker.date.anytime()).format('YYYY-MM-DD')
```

```typescript ['moment']
moment(faker.date.anytime()).format('YYYY-MM-DD')
```

:::

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` keyword in the spec. The default `'faker'` emits `faker.helpers.fromRegExp(pattern)` and needs no extra dependency. `'randexp'` emits `new RandExp(pattern).gen()`, which supports a wider regex grammar but adds the `randexp` runtime dependency.

### locale

Faker locale code. It switches the named import to `fakerXX` from `@faker-js/faker`, so generated values reflect the target region. The default `'en'` imports `fakerEN`, `'de'` imports `fakerDE`, and `'de_AT'` imports `fakerDE_AT`. See [Faker.js localization](https://fakerjs.dev/api/localization.html) for all locale codes.

### seed

Value passed to `faker.seed(...)` and emitted at the top of each generated factory, giving deterministic output across runs for snapshot tests and reproducible local data. Pass a single number or an array of numbers.

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch: override only the members you want, and anything you omit keeps `resolverFaker`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

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

<!--@include: ../../../snippets/how-to/macros-option.md-->

### printer

Replaces the Faker node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/guide/going-further/printers) covers how overrides compose with macros.

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
