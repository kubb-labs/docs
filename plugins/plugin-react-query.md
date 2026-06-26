---
layout: doc
title: Kubb React Query Plugin
description: Generate TanStack Query hooks for React (useQuery, useMutation,
  useSuspenseQuery, useInfiniteQuery) from OpenAPI.
outline: 2
kind: plugin
id: plugin-react-query
name: React Query
category: framework
type: official
npmPackage: "@kubb/plugin-react-query"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-react-query
featured: true
icon:
  light: https://kubb.dev/feature/tanstack.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - react-query
  - tanstack-query
  - react
  - hooks
  - data-fetching
  - codegen
  - openapi
  - validator
dependencies:
  - plugin-ts
  - plugin-axios
resources:
  documentation: https://kubb.dev/plugins/plugin-react-query
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/react-query
---

# @kubb/plugin-react-query

`@kubb/plugin-react-query` turns each OpenAPI operation into a [TanStack Query](https://tanstack.com/query) hook for React. Read operations become `useFooQuery`, `useFooSuspenseQuery`, or `useFooInfiniteQuery`. Write operations become `useFooMutation`. Every hook is typed: query keys, input variables, response data, and error shape all come from the spec.

The hooks call an HTTP client, so a client plugin must be registered. Add `@kubb/plugin-ts` for the types and either `@kubb/plugin-axios` or `@kubb/plugin-fetch` for the client. Generation errors out when no client plugin is present.

Each hook takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-react-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-react-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-react-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-react-query@beta
```

:::

## Options

### output

Where the generated hooks are written and how they are exported.

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
> Pair `'directory'` with the `group` option to split output into per-tag subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag and uses it as the group key. Operations without a tag land in a default group.
- `'path'` uses the first segment of the operation's URL, so `/pet/findByStatus` groups under `pet`.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder name from a group key. For `tag` groups the default camelCases the tag. For `path` groups it takes the first path segment.

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

### infinite

Enables `useInfiniteQuery` hooks for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response. Pass `false` (default) to skip infinite query generation.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `Partial<Infinite> \| false` |
| Required: | `false`                      |
|  Default: | `false`                      |

With `infinite: false` (the default), a `GET /pets` operation generates `useGetPetsQuery` backed by `useQuery`. Setting `infinite: {}` adds an extra `useGetPetsInfiniteQuery` hook backed by `useInfiniteQuery`:

::: code-group

```typescript [infinite: false (default)]
export function useGetPetsQuery(/* ... */) {
  return useQuery({ queryKey, queryFn })
}
```

```typescript [infinite: {}]
export function useGetPetsInfiniteQuery(/* ... */) {
  return useInfiniteQuery({ queryKey, queryFn, initialPageParam, getNextPageParam })
}
```

:::

Which hook you call depends on the value:

::: code-group

```typescript [infinite: false (default)]
import { useGetPetsQuery } from './src/gen/hooks/useGetPetsQuery'

const { data } = useGetPetsQuery()
```

```typescript [infinite: {}]
import { useGetPetsInfiniteQuery } from './src/gen/hooks/useGetPetsInfiniteQuery'

const { data, fetchNextPage, hasNextPage } = useGetPetsInfiniteQuery()
// data.pages holds each fetched page
```

:::

#### infinite.queryParam

Name of the query parameter that holds the page cursor. Kubb passes `pageParam` into this query key.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'id'`   |

#### infinite.initialPageParam

Initial value for `pageParam` on the first fetch.

|           |           |
| --------: | :-------- |
|     Type: | `unknown` |
| Required: | `false`   |
|  Default: | `0`       |

#### infinite.nextParam

Path to the next-page cursor on the response. Supports dot notation (`'pagination.next.id'`) or array form (`['pagination', 'next', 'id']`).

|           |                              |
| --------: | :--------------------------- |
|     Type: | `string \| string[] \| null` |
| Required: | `false`                      |
|  Default: | `null`                       |

#### infinite.previousParam

Path to the previous-page cursor on the response. Supports dot notation (`'pagination.prev.id'`) or array form (`['pagination', 'prev', 'id']`).

|           |                              |
| --------: | :--------------------------- |
|     Type: | `string \| string[] \| null` |
| Required: | `false`                      |
|  Default: | `null`                       |

#### infinite.cursorParam

> [!WARNING]
> `cursorParam` is deprecated. Use `nextParam` and `previousParam` for finer pagination control.

Path to the cursor field on the response. Leave it `null` when the cursor is not known.

|           |                  |
| --------: | :--------------- |
|     Type: | `string \| null` |
| Required: | `false`          |
|  Default: | `null`           |

### suspense

Adds `useSuspenseQuery` hooks alongside the regular `useQuery` ones. The plugin generates these by default. Set `suspense` to `false` to skip them.

Suspense queries throw promises while loading and need a `<Suspense>` boundary in the React tree. TanStack Query v5+ only.

|           |                            |
| --------: | :------------------------- |
|     Type: | `Partial<object> \| false` |
| Required: | `false`                    |
|  Default: | `{}`                       |

With `suspense` enabled (the default), a `GET /pets` operation generates both a regular and a suspense hook. Set `suspense: false` to drop the suspense variant:

::: code-group

```typescript [suspense: {} (default)]
export function useGetPetsQuery(/* ... */) {
  return useQuery({ queryKey, queryFn })
}

export function useGetPetsSuspenseQuery(/* ... */) {
  return useSuspenseQuery({ queryKey, queryFn })
}
```

```typescript [suspense: false]
export function useGetPetsQuery(/* ... */) {
  return useQuery({ queryKey, queryFn })
}
```

:::

Which hook you reach for depends on the value:

::: code-group

```typescript [suspense: {} (default)]
import { useGetPetsSuspenseQuery } from './src/gen/hooks/useGetPetsSuspenseQuery'

// inside a <Suspense> boundary, data is already resolved with no isLoading flag
const { data } = useGetPetsSuspenseQuery()
```

```typescript [suspense: false]
import { useGetPetsQuery } from './src/gen/hooks/useGetPetsQuery'

const { data, isLoading, error } = useGetPetsQuery()
```

:::

### query

Configures the query hooks. The plugin generates them by default. Pass `false` to skip the hooks and emit only `queryOptions(...)` helpers, so you can call `useQuery` yourself in app code.

|           |                           |
| --------: | :------------------------ |
|     Type: | `Partial<Query> \| false` |
| Required: | `false`                   |
|  Default: | `{}`                      |

#### query.methods

HTTP methods treated as queries. Operations using one of these methods generate a `useQuery`-style hook (or a `queryOptions` helper) instead of a mutation.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<string>` |
| Required: | `false`         |
|  Default: | `['get']`       |

#### query.importPath

Module used in the `import { useQuery } from '...'` statement at the top of every generated hook file. Point it at your own re-export of TanStack Query, for example a wrapper that injects a default `queryClient`.

|           |                           |
| --------: | :------------------------ |
|     Type: | `string`                  |
| Required: | `false`                   |
|  Default: | `'@tanstack/react-query'` |

### queryKey

Builds the `queryKey` for each generated hook. Use it to add a version namespace, key off the operation ID, or match an existing `queryClient.invalidateQueries` strategy. The callback receives the operation `node` and the active `casing`, and returns the array of values that make up the key.

|           |                                                                       |
| --------: | :-------------------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Required: | `false`                                                               |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any string you want emitted as a literal in `JSON.stringify(...)`.

A key built from the operation's first tag plus its path parameters changes the generated `queryKey` helper:

::: code-group

```typescript [queryKey builder]
queryKey: ({ node }) => {
  const tags = node.tags.map((tag) => JSON.stringify(tag))
  const pathParams = node.parameters.filter((param) => param.in === 'path').map((param) => param.name)
  return [...tags, ...pathParams]
}
```

```typescript [Generated output]
export const getUserByNameQueryKey = ({ username }: { username: GetUserByNamePathParams['username'] }) => ['user', username] as const
```

:::

### mutation

Configures the mutation hooks. The plugin generates them by default. Set to `false` to skip mutation generation.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `Partial<Mutation> \| false` |
| Required: | `false`                      |
|  Default: | `{}`                         |

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these methods generate a `useMutation`-style hook instead of a query. Narrow the list if your API uses one of these methods for reads.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<string>`                      |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Module used in the `import { useMutation } from '...'` statement at the top of every generated hook file. Point it at your own wrapper.

|           |                           |
| --------: | :------------------------ |
|     Type: | `string`                  |
| Required: | `false`                   |
|  Default: | `'@tanstack/react-query'` |

### mutationKey

Builds the `mutationKey` for each mutation hook. Use it when you batch invalidations or read mutation state with `useMutationState`. The callback receives the same `{ node, casing }` props as `queryKey`.

|           |                                                                       |
| --------: | :-------------------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Required: | `false`                                                               |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap literal strings in `JSON.stringify(...)`.

### customOptions

Routes every generated hook through your own function that returns extra options, such as `onSuccess`, `onError`, or `select`. Use it to centralize cache invalidation, error toasts, or analytics instead of repeating them at every call site. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

|           |                 |
| --------: | :-------------- |
|     Type: | `CustomOptions` |
| Required: | `false`         |

#### customOptions.importPath

Module of your custom-options hook. Generated code imports it as a named import, `import { ${name} } from '${importPath}'`. Use a relative path from the generated file or a bare specifier.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

#### customOptions.name

Exported function name of your custom-options hook. Generated code imports it as a named import, `import { ${name} } from '${importPath}'`, so your module must export this name.

|           |                          |
| --------: | :----------------------- |
|     Type: | `string`                 |
| Required: | `false`                  |
|  Default: | `'useCustomHookOptions'` |

### validator

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

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

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

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                              |
| --------: | :----------------------------------------------------------- |
|     Type: | `Partial<ResolverReactQuery> & ThisType<ResolverReactQuery>` |
| Required: | `false`                                                      |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts) for the types.
- A client plugin, [`@kubb/plugin-axios`](/plugins/plugin-axios) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch), for the HTTP layer. The hooks call its functions, so generation errors out when no client plugin is registered.

Set `validator` to `'zod'` and the plugin also depends on [`@kubb/plugin-zod`](/plugins/plugin-zod), which then has to be in the plugins list.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginReactQuery({
      output: { path: './hooks' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Hooks`,
      },
      client: 'fetch',
      mutation: { methods: ['post', 'put', 'delete'] },
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
        previousParam: ['pagination', 'prev', 'cursor'],
      },
      query: {
        methods: ['get'],
        importPath: '@tanstack/react-query',
      },
      suspense: {},
    }),
  ],
})
```

:::

## See Also

- [TanStack Query](https://tanstack.com/query)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md)
