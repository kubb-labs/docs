---
layout: doc
title: Kubb SWR Plugin
description: Generate SWR hooks (useSWR, useSWRMutation) from OpenAPI specifications.
outline: 2
kind: plugin
id: plugin-swr
name: SWR
category: framework
type: official
npmPackage: "@kubb/plugin-swr"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-swr
featured: true
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - swr
  - react
  - hooks
  - data-fetching
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-client
resources:
  documentation: https://kubb.dev/plugins/plugin-swr
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/swr
---

# @kubb/plugin-swr

`@kubb/plugin-swr` turns your OpenAPI operations into SWR hooks. It emits a `useSWR` hook for each query and a `useSWRMutation` hook for each write. The hooks reuse the types from `@kubb/plugin-ts` and call the HTTP client from `@kubb/plugin-client`, so every request and response stays typed.

This plugin needs both [`@kubb/plugin-ts`](/plugins/plugin-ts) and [`@kubb/plugin-client`](/plugins/plugin-client).

Each hook takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

**See also**

- [SWR](https://swr.vercel.app)

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

Where the generated hook files are written and how they are exported.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Output`                                       |
| Required: | `false`                                        |
|  Default: | `{ path: 'hooks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'hooks.ts'`.

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'hooks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'hooks.ts'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`.

### client

Sets how the generated hooks talk to the HTTP client. Choose the bundled client or a custom module, the shape of the returned data, the base URL, and the parameter casing.

|           |                                                                               |
| --------: | :---------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL? }` |
| Required: | `false`                                                                       |

When no `@kubb/plugin-client` is present and no `client.importPath` is set, the plugin injects its own client into `.kubb/client.ts`.

#### client.client

Which bundled HTTP client to emit into `.kubb/client.ts`. `'axios'` needs `axios` at runtime. `'fetch'` uses the global `fetch`. Cannot be combined with `client.importPath`.

|           |                    |
| --------: | :----------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`            |
|  Default: | `'axios'`          |

#### client.importPath

Path to a custom client module. The generated hooks import their HTTP runtime from here instead of the bundled client. Accepts relative paths and bare module specifiers. The value is used as written. Cannot be combined with `client.client`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

#### client.clientType

Shape of the generated client. Only `'function'` works with this plugin.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `'function' \| 'class' \| 'staticClass'` |
| Required: | `false`                                  |
|  Default: | `'function'`                             |

#### client.dataReturnType

Shape of the value each hook returns. `'data'` returns only the response body. `'full'` returns the full response as a discriminated union keyed by HTTP status code.

|           |                  |
| --------: | :--------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`          |
|  Default: | `'data'`         |

#### client.baseURL

Base URL prepended to every request. When omitted, the adapter's server URL is used (typically `servers[0].url`).

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### parser

Validates the response body before the hook returns it. `false` skips validation and casts the response to the generated type. `'zod'` runs the response through the matching Zod schema from `@kubb/plugin-zod`, which adds that plugin as a dependency.

|           |                  |
| --------: | :--------------- |
|     Type: | `false \| 'zod'` |
| Required: | `false`          |
|  Default: | `false`          |

### query

Configures the generated `useSWR` hooks. Pass an object to change the HTTP methods or the import path. Pass `false` to skip query hook generation.

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `Partial<Query> \| false`                 |
| Required: | `false`                                   |
|  Default: | `{ methods: ['get'], importPath: 'swr' }` |

```typescript [Query]
type Query = {
  methods?: Array<string>
  importPath?: string
}
```

#### query.methods

HTTP methods that produce query hooks.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<string>` |
| Required: | `false`         |
|  Default: | `['get']`       |

#### query.importPath

Module that `useSWR` is imported from. The plugin emits `import useSWR from '${importPath}'`. Accepts relative and absolute paths and is used as written. Relative paths resolve against the generated file.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'swr'`  |

::: code-group

```typescript ['swr' (default)]
import useSWR from 'swr'
```

```typescript ['custom/swr']
import useSWR from 'custom/swr'
```

:::

### queryKey

Builds the SWR key for each query hook. Pass a function that receives the operation and its schemas and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |               |
| --------: | :------------ |
|     Type: | `Transformer` |
| Required: | `false`       |

### mutation

Configures the generated `useSWRMutation` hooks. Pass an object to change the HTTP methods or the import path. Pass `false` to skip mutation hook generation.

|           |                                                                              |
| --------: | :--------------------------------------------------------------------------- |
|     Type: | `Partial<Mutation> \| false`                                                 |
| Required: | `false`                                                                      |
|  Default: | `{ methods: ['post', 'put', 'patch', 'delete'], importPath: 'swr/mutation' }` |

```typescript [Mutation]
type Mutation = {
  methods?: Array<string>
  importPath?: string
}
```

#### mutation.methods

HTTP methods that produce mutation hooks.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<string>`                      |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Module that `useSWRMutation` is imported from. The plugin emits `import useSWRMutation from '${importPath}'`. Accepts relative and absolute paths and is used as written. Relative paths resolve against the generated file.

|           |                  |
| --------: | :--------------- |
|     Type: | `string`         |
| Required: | `false`          |
|  Default: | `'swr/mutation'` |

::: code-group

```typescript ['swr/mutation' (default)]
import useSWRMutation from 'swr/mutation'
```

```typescript ['custom/mutation']
import useSWRMutation from 'custom/mutation'
```

:::

### mutationKey

Builds the SWR key for each mutation hook. Pass a function that receives the operation and its schemas and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |               |
| --------: | :------------ |
|     Type: | `Transformer` |
| Required: | `false`       |

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`. The `pattern` is a string (exact match) or a `RegExp` (fuzzy match).

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Include>` |
| Required: | `false`          |

### exclude

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` and `pattern`. When both are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |

### override

Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. Rules cannot nest. Entries run top to bottom, and the first match merges onto the plugin defaults.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |

### resolver

Changes how the plugin names generated functions and types. Override only the methods you want to change. Anything you omit falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name)` to reuse the built-in name.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverSwr> & ThisType<ResolverSwr>` |
| Required: | `false`                                        |

### macros

Rewrites AST nodes before they are printed to source. Each [macro](/docs/5.x/concepts/macros) callback receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginSwr({
      output: { path: './hooks' },
      group: { type: 'tag', name: ({ group }) => `${group}Hooks` },
      client: { dataReturnType: 'data' },
      query: { methods: ['get'], importPath: 'swr' },
      mutation: { methods: ['post', 'put', 'delete'] },
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md)
