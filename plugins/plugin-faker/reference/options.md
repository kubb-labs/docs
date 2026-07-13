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
| [`output`](#output) | `Output` | `{ path: 'mocks', barrel: { type: 'named' } }` | Where the generated files are written and exported |
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

How the plugin consolidates generated code. `'directory'` (the default) writes one file per operation or schema under `output.path`. `'file'` writes everything into a single file, where `output.path` must include the extension such as `'mocks.ts'`. Pairing `mode: 'file'` with `group` is invalid and fails with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

Controls how the generated `index.ts` (barrel) re-exports the plugin's output. The default `{ type: 'named' }` re-exports each symbol by name, `{ type: 'all' }` uses `export *`, `{ nested: true }` adds a barrel in every subdirectory, and `false` skips the barrel and drops the plugin's files from the root `index.ts`.

#### output.banner

Text added to the top of every generated file, for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string, or a function that builds one from a `BannerMeta` object carrying the document info (`title`, `description`, `version`, `baseURL`) and per-file context (`filePath`, `baseName`, `isBarrel`, `isAggregation`), so a directive such as `'use server'` can skip barrel files.

#### output.footer

Text added to the bottom of every generated file. It mirrors `banner` for closing comments, taking the same string or `(meta: BannerMeta) => string`. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Grouping applies only to `output.mode: 'directory'` and is invalid with `mode: 'file'`.

#### group.type

Property used to assign each operation to a group, required whenever `group` is set. `'tag'` uses the operation's first tag and `'path'` the first URL segment, such as `pet` for `/pet/{petId}`. An operation with no tag goes in the `default` group.

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

Generates only the operations and schemas that match at least one entry, skipping everything else. Each entry sets a `type` of `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`, plus a `pattern` that is a string for an exact match or a `RegExp` for fuzzy matches. Stack entries to narrow further, such as `{ type: 'tag', pattern: 'pet' }`.

### exclude

Skips any operation or schema that matches at least one entry, the opposite of `include`. Entries use the same `type` values and `pattern` (string or `RegExp`). When an item matches both lists, `exclude` wins.

### override

Applies a different options object to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom, and only the first match applies, merging onto the plugin defaults. For example, `override: [{ type: 'tag', pattern: 'user', options: { locale: 'de' } }]` switches the `user` tag to German values.

### resolver

Changes how the plugin names generated files and symbols, so you can add a prefix or suffix without forking the plugin. Override only the methods you want and the rest keep their defaults. Inside a method `this` is the full resolver, so a `name` method returning `this.default.name(name) + 'Mock'` appends `Mock` to every factory name. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context. Use `macros` to change AST nodes instead of names.

### macros

Rewrites AST nodes before they are printed, so you can rename operation IDs or drop descriptions without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) supplies one callback per node kind (such as `schema` or `operation`) that receives the node and returns a replacement, or `undefined` to leave it unchanged. Macros run in order, so a later one sees an earlier one's output.

```typescript [A macros array]
import { pluginFaker } from '@kubb/plugin-faker'

pluginFaker({
  macros: [
    {
      name: 'strip-descriptions',
      schema(node) {
        return { ...node, description: undefined }
      },
    },
    {
      name: 'prefix-operation-id',
      operation(node) {
        return { ...node, operationId: `api_${node.operationId}` }
      },
    },
  ],
})
```

### printer

Replaces the Faker node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/guide/going-further/printers) covers how overrides compose with macros.

```typescript [Map integer schemas to a float]
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
