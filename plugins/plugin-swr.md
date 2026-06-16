---
layout: doc
title: Kubb SWR Plugin
description: Generate SWR hooks (useSWR, useSWRMutation) from OpenAPI specifications.
outline: 2
kind: plugin
id: plugin-swr
---

> [!TIP]
> See [SWR](https://swr.vercel.app) for more information about SWR.

# @kubb/plugin-swr

Generate type-safe SWR hooks from your OpenAPI schema for data fetching, caching, and mutations.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-swr@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-swr@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-swr@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-swr@beta
```

:::

## Options

### output

Set where the plugin writes its files and how the output behaves.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Output`                                       |
| Required: | `false`                                        |
|  Default: | `{ path: 'hooks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Use a folder to keep each generator's output isolated (`'types'`, `'clients'`, `'hooks'`). To put everything in one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'hooks'` |

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
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`, since a single-file output has nothing to group. Combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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

### group

Grouping combines files in a folder based on a specific `type`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

### client

Client configuration for HTTP request generation.

|           |                                                                                         |
| --------: | :-------------------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, bundle?, paramsCasing? }` |
| Required: | `false`                                                                                 |

### paramsType

Defines how parameters are passed to generated functions.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

### paramsCasing

Transform parameter names to a specific casing format.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### pathParamsType

Defines how pathParams are passed to generated functions.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

### parser

Runtime validator applied to the response body before it is returned.

- `false` (default) skips validation and casts the response to the generated type.
- `'zod'` pipes the response through the Zod schema from `@kubb/plugin-zod`.

|           |                  |
| --------: | :--------------- |
|     Type: | `false \| 'zod'` |
| Required: | `false`          |
|  Default: | `false`          |

### query

Override some `useSWR` behaviors. Pass `false` to disable query hook generation.

|           |         |
| --------: | :------ |
|     Type: | `Query` |
| Required: | `false` |

```typescript [Query]
type Query =
  | {
      methods: Array<HttpMethod>
      importPath?: string
    }
  | false
```

#### query.methods

Define which HttpMethods can be used for queries.

|           |                     |
| --------: | :------------------ |
|     Type: | `Array<HttpMethod>` |
| Required: | `false`             |
|  Default: | `['get']`           |

#### query.importPath

Path to the `useSWR` import.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'swr'`  |

### queryKey

Customize the queryKey that will be used for the query.

|           |                                                                             |
| --------: | :-------------------------------------------------------------------------- |
|     Type: | `(props: { operation: Operation; schemas: OperationSchemas }) => unknown[]` |
| Required: | `false`                                                                     |

### mutation

Override some `useSWRMutation` behaviors. Pass `false` to disable mutation hook generation.

|           |            |
| --------: | :--------- |
|     Type: | `Mutation` |
| Required: | `false`    |

```typescript [Mutation]
type Mutation =
  | {
      methods: Array<HttpMethod>
      importPath?: string
    }
  | false
```

#### mutation.methods

Define which HttpMethods can be used for mutations.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<HttpMethod>`                  |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Path to the `useSWRMutation` import.

|           |                  |
| --------: | :--------------- |
|     Type: | `string`         |
| Required: | `false`          |
|  Default: | `'swr/mutation'` |

### mutationKey

Customize the mutationKey.

|           |                                                                             |
| --------: | :-------------------------------------------------------------------------- |
|     Type: | `(props: { operation: Operation; schemas: OperationSchemas }) => unknown[]` |
| Required: | `false`                                                                     |

### include

Array containing include parameters.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

### exclude

Array containing exclude parameters.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

### override

Array containing override parameters.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

### generators

Define additional generators next to the built-in generators.

|           |                               |
| --------: | :---------------------------- |
|     Type: | `Array<Generator<PluginSwr>>` |
| Required: | `false`                       |

### resolver

Override naming conventions for function names and types.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverSwr> & ThisType<ResolverSwr>` |
| Required: | `false`                                        |

### macros

A list of [macros](/docs/5.x/concepts/macros) that rewrite generated nodes before printing.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

## Dependencies

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-client`](/plugins/plugin-client)

## Example

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: {
    path: './petStore.yaml',
  },
  output: {
    path: './src/gen',
  },
  plugins: [
    pluginTs(),
    pluginSwr({
      output: {
        path: './hooks',
      },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Hooks`,
      },
      client: {
        dataReturnType: 'data',
      },
      mutation: {
        methods: ['post', 'put', 'delete'],
      },
      query: {
        methods: ['get'],
        importPath: 'swr',
      },
    }),
  ],
})
```

:::
