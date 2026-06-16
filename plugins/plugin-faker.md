---
layout: doc
title: Kubb Faker Plugin
description: Generate Faker.js mock-data factories from OpenAPI for tests,
  Storybook, and seeded local data.
outline: 2
kind: plugin
id: plugin-faker
---

# @kubb/plugin-faker

Generate a mock-data factory function for every schema in your OpenAPI spec, powered by [Faker.js](https://fakerjs.dev/). Call `createPet()` and you get a realistic `Pet` object, which lets you run tests, render Storybook stories, and work on local data without a running backend.

Pair with `@kubb/plugin-msw` to mock entire endpoints, or use the factories directly in your test suite.

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

Use a folder to keep each generator's output isolated (`'types'`, `'clients'`, `'hooks'`). To put everything in one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

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

Text prepended to every generated file. Use it for license headers, lint disables, or `@ts-nocheck` directives.

Pass a string for a static banner. Pass a function to compute the banner from each file's `RootNode` (the AST root containing path, schema, and operation context).

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

Text appended at the end of every generated file. It mirrors `banner`. Use it for closing comments, re-enabling lint rules, or marker lines.

Pass a string for a static footer, or a function that receives the file's `RootNode` and returns the footer text.

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

#### output.override

Allows the plugin to overwrite hand-written files that share a name with a generated file.

- `false` (default): Kubb skips a file if it already exists and is not marked as generated. This protects manual edits.
- `true`: Kubb overwrites any file at the target path, including hand-written ones.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

> [!WARNING]
> Enable this only when you are sure the target folder contains nothing you need to keep. Local edits are lost on the next generation.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { override: true },
    }),
  ],
})
```

:::

### group

Splits generated files into subfolders based on the operation's tag, so each tag in your OpenAPI spec gets its own directory.

Without `group`, every file lands in the plugin's `output.path` folder. With `group`, files are bucketed under `{output.path}/{groupName}/`, where `groupName` is derived from the operation's first tag.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default), where each group becomes a folder. It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Pass `group.name` to customize the folder name, for example `name: ({ group }) => \`${group}Controller\``to keep the pre-v5`petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

Today only `'tag'` is supported: Kubb reads the first tag on the operation (`operation.getTags().at(0)?.name`) and uses it as the group key. Operations without a tag are placed in a default group.

|           |         |
| --------: | :------ |
|     Type: | `'tag'` |
| Required: | `true`  |

> [!NOTE]
> `Required: true*` is conditional. It applies only when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder/identifier name from a group key (the operation's first tag).

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### dateParser

Library used to format `date`, `time`, and `datetime` fields that are represented as strings.

Use a value other than `'faker'` when you already have a date library in the project and want consistent formatting across mocks and runtime. The plugin auto-imports the default export of the library you choose.

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

Maps OpenAPI schema names to specific Faker expressions. Use this when the schema name does not give Faker enough context to pick a sensible value (`'email'`, `'phone'`, `'avatarUrl'`).

Keys are the schema name (case-sensitive), and values are the JavaScript expression that produces the mock value.

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

Seed value passed to `faker.seed(...)`. Set it to get deterministic output across runs, which helps with snapshot tests and reproducible local data.

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

Faker locale used for generated mock values. Switches the named import to `fakerXX` from `@faker-js/faker` so names, addresses, and phone numbers reflect the target region.

Defaults to `'en'`, which imports `fakerEN`.

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
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

Applies a different set of plugin options to operations that match a pattern. Use this when most of your API should follow the global config, but a handful of endpoints need different treatment.

Each entry has the same `type` and `pattern` shape as `include`/`exclude`, plus an `options` object that overrides the plugin's options for matched operations.

Entries are evaluated top to bottom. The first matching entry's `options` is merged onto the plugin defaults, and later entries do not stack.

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

```typescript [Use a different enum style for the user tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enumType: 'asConst',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { enumType: 'literal' },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run alongside the plugin's built-in generators. Each generator can emit additional files or post-process existing ones using the plugin's AST and options.

Use this when you need output the plugin does not produce out of the box (a custom client wrapper, an extra index, a metadata file). For end-to-end guidance, see [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                 |
| --------: | :------------------------------ |
|     Type: | `Array<Generator<PluginFaker>>` |
| Required: | `false`                         |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### resolver

Customizes the naming of the generated factory helpers. A common reason to set it is to append `Mock` or `Factory` so the helpers do not clash with the imported types.

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
