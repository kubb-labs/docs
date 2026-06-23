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
  - plugin-axios
resources:
  documentation: https://kubb.dev/plugins/plugin-swr
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/swr
---

# @kubb/plugin-swr

`@kubb/plugin-swr` turns each OpenAPI operation into an [SWR](https://swr.vercel.app) hook. Read operations become `useSWR` hooks. Write operations become `useSWRMutation` hooks. Every hook is typed: keys, input variables, response data, and error shape all come from the spec.

The hooks call an HTTP client, so a client plugin must be registered. Add `@kubb/plugin-ts` for the types and either `@kubb/plugin-axios` or `@kubb/plugin-fetch` for the client. Generation errors out when no client plugin is present.

Each hook takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

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

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension, such as `'hooks.ts'`.

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
- `false` skips the barrel. The plugin's files are also excluded from the root `index.ts`.

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
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag and uses it as the group key. Operations without a tag land in a default group.
- `'path'` uses the first segment of the operation's URL, so `/pet/findByStatus` groups under `pet`.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

#### group.name

Function that builds the folder name from a group key.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                  |
|  Default: | `(ctx) => camelCase(ctx.group)`          |

### client

Selects which registered client plugin the generated hooks call. Set `'axios'` to use `@kubb/plugin-axios` or `'fetch'` to use `@kubb/plugin-fetch`. When omitted, the plugin auto-detects the single client plugin in the config, so you only need this option to disambiguate when several client plugins are registered. A client plugin must be registered, since the hooks call its functions.

|           |                      |
| --------: | :------------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`              |

### query

Configures the generated `useSWR` hooks. The plugin generates them by default. Pass an object to change the HTTP methods or the import path. Pass `false` to skip query hook generation.

|           |                           |
| --------: | :------------------------ |
|     Type: | `Partial<Query> \| false` |
| Required: | `false`                   |
|  Default: | `{}`                      |

#### query.methods

HTTP methods treated as queries. Operations using one of these generate a `useSWR` hook instead of a mutation.

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

Changing `importPath` rewrites the import at the top of every query hook:

::: code-group

```typescript ['swr' (default)]
import useSWR from 'swr'
```

```typescript ['custom/swr']
import useSWR from 'custom/swr'
```

:::

You call the generated hook the same way no matter the import path. Only the `useSWR` import inside the hook changes:

```typescript
import { useFindPetsByStatus } from './src/gen/hooks/useFindPetsByStatus'

const { data, error, isLoading } = useFindPetsByStatus()
```

### queryKey

Builds the SWR key for each query hook. The callback receives the operation `node` and the active `casing`, and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |               |
| --------: | :------------ |
|     Type: | `Transformer` |
| Required: | `false`       |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### mutation

Configures the generated `useSWRMutation` hooks. The plugin generates them by default. Pass an object to change the HTTP methods or the import path. Pass `false` to skip mutation hook generation.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `Partial<Mutation> \| false` |
| Required: | `false`                      |
|  Default: | `{}`                         |

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these generate a `useSWRMutation` hook instead of a query.

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

Changing `importPath` rewrites the import at the top of every mutation hook:

::: code-group

```typescript ['swr/mutation' (default)]
import useSWRMutation from 'swr/mutation'
```

```typescript ['custom/mutation']
import useSWRMutation from 'custom/mutation'
```

:::

You call the generated hook the same way no matter the import path. Only the `useSWRMutation` import inside the hook changes:

```typescript
import { useAddPet } from './src/gen/hooks/useAddPet'

const { trigger } = useAddPet()
```

### mutationKey

Builds the SWR key for each mutation hook. The callback receives the operation `node` and the active `casing`, and returns the key array. The plugin uses its built-in transformer when this is unset.

|           |               |
| --------: | :------------ |
|     Type: | `Transformer` |
| Required: | `false`       |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### parser

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`.

- `false` (default) does no validation. The client returns the response cast to the generated type.
- `'zod'` validates response bodies only.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction. `request` validates the request body and query parameters before the call. `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`.

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`. The `pattern` is a string (exact match) or a `RegExp` (fuzzy match).

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

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` and `pattern`. When both are set, `exclude` wins.

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

Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. Rules cannot nest. Entries run top to bottom, and the first match merges onto the plugin defaults.

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

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts) for the types.
- A client plugin, [`@kubb/plugin-axios`](/plugins/plugin-axios) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch), for the HTTP layer. The hooks call its functions, so generation errors out when no client plugin is registered.

Set `parser` to `'zod'` and the plugin also depends on [`@kubb/plugin-zod`](/plugins/plugin-zod), which then has to be in the plugins list.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginSwr({
      output: { path: './hooks' },
      group: { type: 'tag', name: ({ group }) => `${group}Hooks` },
      client: 'fetch',
      query: { methods: ['get'], importPath: 'swr' },
      mutation: { methods: ['post', 'put', 'delete'] },
    }),
  ],
})
```

:::

## See Also

- [SWR](https://swr.vercel.app)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md)
