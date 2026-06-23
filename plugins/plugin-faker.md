---
layout: doc
title: Kubb Faker Plugin
description: Generate Faker.js mock-data factories from OpenAPI for tests,
  Storybook, and seeded local data.
outline: 2
kind: plugin
id: plugin-faker
name: Faker
category: mocks
type: official
npmPackage: "@kubb/plugin-faker"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-faker
featured: false
icon:
  light: https://kubb.dev/feature/faker.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - faker
  - mock-data
  - mocks
  - fixtures
  - testing
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-faker
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-faker/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/faker
---

# @kubb/plugin-faker

`@kubb/plugin-faker` builds a mock-data factory for every schema in your OpenAPI spec with [Faker.js](https://fakerjs.dev/). Call `createPet()` to get a realistic `Pet` object. Use the factories in tests, Storybook stories, and local development without a backend.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-faker@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-faker@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-faker@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-faker@beta
```

:::

## Options

### output

Where the generated mock factories are written and how they are exported.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Output`                                       |
| Required: | `false`                                        |
|  Default: | `{ path: 'mocks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mocks.ts'`.

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'mocks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'mocks.ts'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

- `{ type: 'named' }` re-exports each symbol by name. Best for tree-shaking and explicit imports.
- `{ type: 'all' }` uses `export *`. Smaller barrel file, but exports everything.
- `{ nested: true }` creates a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel entirely. The plugin's files are also excluded from the root `index.ts`.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'named' \| 'all', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

> [!TIP]
> Pick `'named'` when consumers care about which symbols they import (better tree-shaking, friendlier auto-import). Pick `'all'` when the file count is small and you want a one-line barrel.

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode` (the AST root with the path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode` and returns the text.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

### group

Splits generated files into subfolders by the operation's tag or path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-group barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── createPet.ts
│   └── getPet.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Controller` to the group keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag (`operation.getTags().at(0)?.name`). Operations without a tag fall into a default group.
- `'path'` uses the first segment of the operation's URL.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that turns a group key (the operation's first tag or first path segment) into a folder name.

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `(context: { group: string }) => string`  |
| Required: | `false`                                   |
|  Default: | camelCased tag, or first path segment for `path` groups |

### dateParser

Library used to format `date`, `time`, and `datetime` fields represented as strings. Pick a value other than `'faker'` when your project already uses a date library and you want consistent formatting. Any library exporting a default function works, and Kubb adds the import for you.

|           |                                            |
| --------: | :----------------------------------------- |
|     Type: | `'faker' \| 'dayjs' \| 'moment' \| string` |
| Required: | `false`                                    |
|  Default: | `'faker'`                                  |

A `date` field renders differently per parser:

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

You call the factory the same way for every parser. Only the format of the generated date field changes:

```typescript
import { createPet } from './src/gen/mocks/createPet'

const pet = createPet()
```

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` keyword in the spec.

- `'faker'` (default) uses `faker.helpers.fromRegExp`. No extra dependency.
- `'randexp'` uses the `randexp` package. It supports a wider regex grammar, but adds a runtime dependency.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'faker' \| 'randexp'` |
| Required: | `false`                |
|  Default: | `'faker'`              |

::: code-group

```typescript ['faker' (default)]
faker.helpers.fromRegExp('^[A-Z]+$')
```

```typescript ['randexp']
new RandExp(/^[A-Z]+$/).gen()
```

:::

You call the factory the same way for both libraries. Only the source of the generated pattern string changes:

```typescript
import { createPet } from './src/gen/mocks/createPet'

const pet = createPet()
```

### mapper

Maps a schema name to a custom Faker expression. Use it when the schema name does not give Faker enough context to pick a sensible value, such as `'email'`, `'avatarUrl'`, or `'phoneNumber'`. Keys are the case-sensitive schema name. Values are the JavaScript expression that produces the mock value.

|           |                          |
| --------: | :----------------------- |
|     Type: | `Record<string, string>` |
| Required: | `false`                  |
|  Default: | `{}`                     |

### locale

Faker locale code. It switches the named import to `fakerXX` from `@faker-js/faker`, so names, addresses, and phone numbers reflect the target region. The default `'en'` imports `fakerEN`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'en'`   |

> [!TIP]
> See [Faker.js localization](https://fakerjs.dev/api/localization.html) for the full list of locale codes.

::: code-group

```typescript ['en' (default)]
import { fakerEN as faker } from '@faker-js/faker'
```

```typescript ['de']
import { fakerDE as faker } from '@faker-js/faker'
```

```typescript ['de_AT']
import { fakerDE_AT as faker } from '@faker-js/faker'
```

:::

You call the factory the same way for every locale. Only the generated values change, so names and addresses reflect the region:

```typescript
import { createPet } from './src/gen/mocks/createPet'

const pet = createPet()
```

### seed

Value passed to `faker.seed(...)`. Set it for deterministic output across runs, which helps with snapshot tests and reproducible local data.

|           |                      |
| --------: | :------------------- |
|     Type: | `number \| number[]` |
| Required: | `false`              |

### include

Generates only the operations and schemas that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

### exclude

Skips any operation or schema that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

### override

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. That object accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

### resolver

Changes how the plugin names the generated factory helpers. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name)` to reuse the built-in name. A common use is to append `Mock` or `Factory` so helpers do not clash with imported types.

|           |                                                    |
| --------: | :------------------------------------------------- |
|     Type: | `Partial<ResolverFaker> & ThisType<ResolverFaker>` |
| Required: | `false`                                            |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.

### macros

Rewrites AST nodes before they are printed to source. Use it to drop descriptions or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

### printer

Replaces the Faker handler for a specific schema type, such as `'integer'`, `'date'`, or `'ref'`. Each handler returns the Faker expression as a string. Use `this.transform` to recurse into nested nodes, and `this.options` to read printer options.

|           |                                 |
| --------: | :------------------------------ |
|     Type: | `{ nodes?: PrinterFakerNodes }` |
| Required: | `false`                         |

## Dependencies

This plugin depends on [`@kubb/plugin-ts`](/plugins/plugin-ts) for the types each factory returns. Keep `pluginTs()` in the plugins array. No other plugin is required.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
    }),
    pluginFaker({
      output: { path: './mocks' },
      seed: [100],
    }),
  ],
})
```

:::

## See also

- [Faker.js](https://fakerjs.dev/)
- [@kubb/plugin-ts](/plugins/plugin-ts)
- [@kubb/plugin-msw](/plugins/plugin-msw)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-faker/CHANGELOG.md)
