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

Generate type-safe SWR hooks from your OpenAPI schema. The plugin emits `useSWR` hooks for queries and `useSWRMutation` hooks for writes.

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

Organize `output.mode: 'directory'` output into per-tag or per-path subdirectories.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

### client

Configure how the generated hooks call the HTTP client. Set the client kind, the shape of the returned data, the base URL, whether to bundle the client, the import path, and parameter casing.

|           |                                                                                         |
| --------: | :-------------------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, bundle?, paramsCasing? }` |
| Required: | `false`                                                                                 |

### paramsType

Set how the generated hooks receive request parameters. `'inline'` spreads each parameter as its own argument. `'object'` groups them into a single argument.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

### paramsCasing

Apply a casing convention to parameter names. Set `'camelcase'` to rename parameters to camelCase. Leave it unset to keep the names from the OpenAPI document.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### pathParamsType

Set how the generated hooks receive path parameters. `'inline'` spreads each path parameter as its own argument. `'object'` groups them into a single argument. When `paramsType` is `'object'`, path parameters default to `'object'` as well.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

### parser

Validate the response body before the hook returns it. `false` skips validation and casts the response to the generated type. `'zod'` runs the response through the matching Zod schema from `@kubb/plugin-zod`, which adds that plugin as a dependency.

|           |                  |
| --------: | :--------------- |
|     Type: | `false \| 'zod'` |
| Required: | `false`          |
|  Default: | `false`          |

### query

Configure the generated `useSWR` hooks. Pass an object to change the HTTP methods or the import path. Pass `false` to skip query hook generation.

|           |                        |
| --------: | :--------------------- |
|     Type: | `Partial<Query> \| false` |
| Required: | `false`                |
|  Default: | `{ methods: ['get'], importPath: 'swr' }` |

```typescript [Query]
type Query = {
  methods?: Array<string>
  importPath?: string
}
```

#### query.methods

List the HTTP methods that produce query hooks.

|           |           |
| --------: | :-------- |
|     Type: | `Array<string>` |
| Required: | `false`   |
|  Default: | `['get']` |

#### query.importPath

Set the module that `useSWR` is imported from. The plugin emits `import useSWR from '${importPath}'`. The value accepts relative and absolute paths and is used as written. Relative paths resolve against the generated file.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'swr'`  |

### queryKey

Build the SWR key used by each query hook. Pass a function that receives the operation and its schemas and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |             |
| --------: | :---------- |
|     Type: | `Transformer` |
| Required: | `false`     |

### mutation

Configure the generated `useSWRMutation` hooks. Pass an object to change the HTTP methods or the import path. Pass `false` to skip mutation hook generation.

|           |                           |
| --------: | :------------------------ |
|     Type: | `Partial<Mutation> \| false` |
| Required: | `false`                   |
|  Default: | `{ methods: ['post', 'put', 'patch', 'delete'], importPath: 'swr/mutation' }` |

```typescript [Mutation]
type Mutation = {
  methods?: Array<string>
  importPath?: string
}
```

#### mutation.methods

List the HTTP methods that produce mutation hooks.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<string>`                      |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Set the module that `useSWRMutation` is imported from. The plugin emits `import useSWRMutation from '${importPath}'`. The value accepts relative and absolute paths and is used as written. Relative paths resolve against the generated file.

|           |                  |
| --------: | :--------------- |
|     Type: | `string`         |
| Required: | `false`          |
|  Default: | `'swr/mutation'` |

### mutationKey

Build the SWR key used by each mutation hook. Pass a function that receives the operation and its schemas and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |             |
| --------: | :---------- |
|     Type: | `Transformer` |
| Required: | `false`     |

### include

Limit generation to the listed tags, operations, or paths.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

### exclude

Skip the listed tags, operations, or paths during generation.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

### override

Apply different options to specific tags, operations, or paths.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

### generators

Add custom generators that run alongside the built-in query and mutation generators.

|           |                               |
| --------: | :---------------------------- |
|     Type: | `Array<Generator<PluginSwr>>` |
| Required: | `false`                       |

### resolver

Override the naming for generated function names and types. Pass the methods you want to change. The plugin keeps its defaults for the rest.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverSwr> & ThisType<ResolverSwr>` |
| Required: | `false`                                        |

### macros

Pass a list of [macros](/docs/5.x/concepts/macros) that rewrite generated nodes before they are printed.

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
