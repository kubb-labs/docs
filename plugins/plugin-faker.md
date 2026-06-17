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

Generate a mock-data factory function for every schema in your OpenAPI spec with [Faker.js](https://fakerjs.dev/). Call `createPet()` to get a realistic `Pet` object for tests, Storybook stories, and local data without a running backend. Pair with `@kubb/plugin-msw` to mock entire endpoints, or use the factories directly in your test suite.

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

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Use a folder to keep each generator's output separate (`'types'`, `'clients'`, `'hooks'`). To write everything into one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'mocks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── types/
        ├── Pet.ts
        └── Store.ts
```

:::

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` writes one file per operation or schema under `output.path`. This is the default.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'types.ts'`, `'models.py'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`, since a single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: 'types.ts', mode: 'file' },
    }),
    pluginClient({
      output: { path: 'clients', mode: 'directory' },
      group: { type: 'tag' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    ├── types.ts
    └── clients/
        ├── pet/
        │   └── getPetById.ts
        └── store/
            └── getInventory.ts
```

:::

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

::: code-group

```typescript ['named' (default)]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'named' } },
    }),
  ],
})
```

```typescript [src/gen/types/index.ts]
export { Pet, PetStatus } from './Pet'
export { Store } from './Store'
```

```typescript ['all']
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'all' } },
    }),
  ],
})
```

```typescript [src/gen/types/index.ts]
export * from './Pet'
export * from './Store'
```

```typescript [nested]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: { type: 'named', nested: true } },
    }),
  ],
})
```

```text [Generated tree]
src/gen/types/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports Pet, Store, ...
│   └── Pet.ts
└── store/
    ├── index.ts
    └── Store.ts
```

```typescript [false]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { barrel: false },
    }),
  ],
})
```

```text [Result]
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text prepended to every generated file, for license headers, lint disables, or `@ts-nocheck` directives. Pass a string for a static banner, or a function that computes it from each file's `RootNode` (the AST root holding path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Static banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        banner: '/* eslint-disable */\n// @ts-nocheck',
      },
    }),
  ],
})
```

```typescript [Generated file]
/* eslint-disable */
// @ts-nocheck
export type Pet = {
  id: number
  name: string
}
```

```typescript [Dynamic banner]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        banner: (node) => `// Source: ${node.path}\n// Generated at ${new Date().toISOString()}`,
      },
    }),
  ],
})
```

:::

#### output.footer

Text appended to every generated file, the counterpart to `banner`, for closing comments, re-enabling lint rules, or marker lines. Pass a string for a static footer, or a function that receives the file's `RootNode` and returns the footer text.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

::: code-group

```typescript [Re-enable lint after a banner disable]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: {
        banner: '/* eslint-disable */',
        footer: '/* eslint-enable */',
      },
    }),
  ],
})
```

:::

### group

Splits the generated files into subfolders by each operation's tag or path, so related mocks end up in the same directory. Without `group`, every file lands in the plugin's `output.path` folder. With `group`, each file goes under `{output.path}/{groupName}/`, where `groupName` comes from the operation's first tag or first path segment.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-group barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default), where each group becomes a folder. It is not valid with `output.mode: 'file'`, since a single-file output has nothing to group.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      group: { type: 'tag' },
    }),
  ],
})
```

:::

With the configuration above, the generator emits one folder per tag, named after the camelCased tag:

```text
src/gen/
├── pet/
│   ├── AddPet.ts
│   └── GetPet.ts
└── store/
    ├── CreateStore.ts
    └── GetStoreById.ts
```

Pass `group.name` to customize the folder name, for example `name: ({ group }) => \`${group}Controller\`` to keep the pre-v5 `petController/` layout.

#### group.type

Picks the property that assigns each operation to a group.

- `'tag'` reads the operation's first tag (`operation.getTags().at(0)?.name`) and uses it as the group key. Operations without a tag fall into a default group.
- `'path'` uses the first segment of the operation's URL.

`group.type` is required whenever you set `group`, and `group` itself stays optional.

|           |                  |
| --------: | :--------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`\*         |

> [!NOTE]
> `Required: true`\* is conditional. It applies only when you set the parent `group` option, which stays optional.

#### group.name

Builds the folder name from a group key, which is the operation's first tag or first path segment.

|           |                                       |
| --------: | :------------------------------------ |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                               |
|  Default: | camelCased tag or first path segment  |

### dateParser

Library used to format `date`, `time`, and `datetime` fields represented as strings. Use a value other than `'faker'` when your project already has a date library and you want consistent formatting across mocks and runtime. The plugin auto-imports the default export of the library you choose.

|           |                                            |
| --------: | :----------------------------------------- |
|     Type: | `'faker' \| 'dayjs' \| 'moment' \| string` |
| Required: | `false`                                    |
|  Default: | `'faker'`                                  |

> [!TIP]
> Any library exporting a default function works (`dayjs`, `moment`, `luxon`, ...). Kubb adds the import statement for you.

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

### mapper

Maps OpenAPI schema names to specific Faker expressions, for when the schema name does not give Faker enough context to pick a sensible value (`'email'`, `'phone'`, `'avatarUrl'`). Keys are the case-sensitive schema name, values are the JavaScript expression that produces the mock value.

|           |                          |
| --------: | :----------------------- |
|     Type: | `Record<string, string>` |
| Required: | `false`                  |

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      mapper: {
        email: 'faker.internet.email()',
        avatarUrl: 'faker.image.avatar()',
      },
    }),
  ],
})
```

### paramsCasing

Renames properties inside the generated path/query/header mocks. Body mocks are unaffected.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

> [!IMPORTANT]
> Set the same `paramsCasing` here as on `@kubb/plugin-ts` so the generated mocks stay assignable to the generated types.

### regexGenerator

Library used to generate strings that satisfy a regex `pattern` keyword in the OpenAPI spec.

- `'faker'` (default): `faker.helpers.fromRegExp(...)`. No extra dependency.
- `'randexp'`: uses the `randexp` package, which supports a wider regex grammar (lookaheads, named groups) but adds a runtime dependency.

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

### seed

Seed value passed to `faker.seed(...)`. Set it for deterministic output across runs, which helps with snapshot tests and reproducible local data.

|           |                      |
| --------: | :------------------- |
|     Type: | `number \| number[]` |
| Required: | `false`              |

::: code-group

```typescript [Deterministic seed]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginFaker({ seed: 100 })],
})
```

:::

### locale

Faker locale used for generated mock values. Switches the named import to `fakerXX` from `@faker-js/faker` so names, addresses, and phone numbers reflect the target region. The default `'en'` imports `fakerEN`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'en'`   |

> [!TIP]
> See [Faker.js localization](https://fakerjs.dev/api/localization.html) for the full list of locale codes.

::: code-group

```typescript ['de']
import { fakerDE as faker } from '@faker-js/faker'
```

```typescript ['de_AT']
import { fakerDE_AT as faker } from '@faker-js/faker'
```

:::

### include

Restricts generation to operations that match at least one entry in the list. Anything not matched is skipped.

Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL pattern (`'/pet/{petId}'`).
- `method`: HTTP method (`'get'`, `'post'`, ...).
- `contentType`: the media type of the request body.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
  pattern: string | RegExp
}
```

::: code-group

```typescript [Only the pet tag]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      include: [
        { type: 'method', pattern: 'get' },
        { type: 'path', pattern: /^\/pet/ },
      ],
    }),
  ],
})
```

:::

### exclude

Skips any operation that matches at least one entry in the list. The opposite of `include`.

Each entry filters by one of:

- `tag`: the operation's first tag.
- `operationId`: the operation's `operationId`.
- `path`: the URL pattern (`'/pet/{petId}'`).
- `method`: HTTP method (`'get'`, `'post'`, ...).
- `contentType`: the media type of the request body.

`pattern` accepts a plain string or a `RegExp`. When both `include` and `exclude` are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
  pattern: string | RegExp
}
```

::: code-group

```typescript [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      exclude: [
        { type: 'operationId', pattern: 'deletePet' },
        { type: 'method', pattern: 'delete' },
      ],
    }),
  ],
})
```

:::

### override

Applies a different set of plugin options to operations that match a pattern. Use this when most of your API follows the global config but a few endpoints need different treatment. Each entry has the same `type` and `pattern` shape as `include`/`exclude`, plus an `options` object that overrides the plugin's options for matched operations. Entries are evaluated top to bottom: the first match's `options` is merged onto the plugin defaults, and later entries do not stack.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType'
  pattern: string | RegExp
  options: PluginOptions
}
```

::: code-group

```typescript [Use a different date parser for the user tag]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      dateParser: 'faker',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { dateParser: 'dayjs' },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run alongside the plugin's built-in ones. Each generator can emit extra files or post-process existing ones using the plugin's AST and options. Use this for output the plugin does not produce itself (a custom client wrapper, an extra index, a metadata file). See [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                 |
| --------: | :------------------------------ |
|     Type: | `Array<Generator<PluginFaker>>` |
| Required: | `false`                         |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### resolver

Customizes the names of the generated factory helpers. Set it to append `Mock` or `Factory` so the helpers do not clash with the imported types.

|           |                          |
| --------: | :----------------------- |
|     Type: | `Partial<ResolverFaker>` |
| Required: | `false`                  |

```typescript [Append "Mock" to every factory name]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      resolver: {
        resolveName(name) {
          return `${this.default(name)}Mock`
        },
      },
    }),
  ],
})
```

### macros

A list of [macros](/docs/5.x/concepts/macros) applied to schema/operation nodes before code is printed. Use this to drop descriptions or rewrite metadata before the mock factory is built.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

```typescript [Strip schema descriptions]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      macros: [
        {
          name: 'strip-descriptions',
          schema(node) {
            return { ...node, description: undefined }
          },
        },
      ],
    }),
  ],
})
```

### printer

Replaces the Faker handler for a specific schema type (e.g. `'integer'`, `'date'`, `'ref'`). Each handler returns the Faker expression as a string.

Use `this.transform` to recurse into nested schema nodes and `this.options` to read printer options.

|           |                                 |
| --------: | :------------------------------ |
|     Type: | `{ nodes?: PrinterFakerNodes }` |
| Required: | `false`                         |

::: code-group

```typescript [Use faker.number.float() for integers]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      printer: {
        nodes: {
          integer() {
            return 'faker.number.float()'
          },
        },
      },
    }),
  ],
})
```

```typescript [Override date strings]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginFaker({
      printer: {
        nodes: {
          date(node) {
            if (node.representation === 'string') {
              return 'new Date().toISOString().substring(0, 10)'
            }

            return 'new Date()'
          },
        },
      },
    }),
  ],
})
```

:::

## Dependencies

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)

## Example

::: code-group

```typescript [kubb.config.ts]
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
      paramsCasing: 'camelcase',
    }),
  ],
})
```

:::
