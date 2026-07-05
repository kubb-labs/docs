---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-react-query.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'hooks', barrel: { type: 'named' } }` | Where the generated hooks are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'axios' \| 'fetch'` | — | Which registered client plugin the hooks call |
| [`infinite`](#infinite) | `Partial<Infinite> \| false` | `false` | Generate `useInfiniteQuery` hooks for pagination |
| [`suspense`](#suspense) | `Partial<object> \| false` | `{}` | Generate `useSuspenseQuery` hooks |
| [`query`](#query) | `Partial<Query> \| false` | `{ methods: ['GET'], … }` | Configure the query hooks |
| [`queryKey`](#querykey) | `(props) => unknown[]` | `built-in` | Build the `queryKey` for each query hook |
| [`mutation`](#mutation) | `Partial<Mutation> \| false` | `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], … }` | Configure the mutation hooks |
| [`mutationKey`](#mutationkey) | `(props) => unknown[]` | `built-in` | Build the `mutationKey` for each mutation hook |
| [`customOptions`](#customoptions) | `CustomOptions` | — | Route every hook through your own options function |
| [`hooks`](#hooks) | `boolean` | `false` | Emit `use*` hook functions on top of the factories |
| [`resolver`](#resolver) | `Partial<ResolverReactQuery>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |

### output

Where the generated hooks are written and how they are exported.

|          |                                                |
| -------: | :--------------------------------------------- |
|    Type: | `Output`                                       |
| Default: | `{ path: 'hooks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'hooks.ts'`.

|          |           |
| -------: | :-------- |
|    Type: | `string`  |
| Default: | `'hooks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'hooks.ts'`).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'directory' \| 'file'` |
| Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

- `{ type: 'named' }` re-exports each symbol by name. Best for tree-shaking and explicit imports.
- `{ type: 'all' }` uses `export *`. Smaller barrel file, but exports everything.
- `{ nested: true }` creates a barrel in every subdirectory, so callers can import from any depth.
- `false` skips the barrel entirely. The plugin's files are also excluded from the root `index.ts`.

|          |                                                         |
| -------: | :------------------------------------------------------ |
|    Type: | `{ type: 'named' \| 'all', nested?: boolean } \| false` |
| Default: | `{ type: 'named' }`                                     |

> [!TIP]
> Pick `'named'` when consumers care about which symbols they import (better tree-shaking, friendlier auto-import). Pick `'all'` when the file count is small and you want a one-line barrel.

::: code-group

```typescript ['named' (default)]
// src/gen/hooks/index.ts
export { getPetsQueryKey, getPetsQueryOptions } from './useGetPets'
export { createPetMutationKey, createPetMutationOptions } from './useCreatePet'
```

```typescript ['all']
// src/gen/hooks/index.ts
export * from './useGetPets'
export * from './useCreatePet'
```

```text [nested]
src/gen/hooks/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPetsQueryKey, getPetsQueryOptions, ...
│   └── useGetPets.ts
└── store/
    ├── index.ts
    └── useGetOrderById.ts
```

```text [false]
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from a `BannerMeta` object. The meta carries the document info (`title`, `description`, `version`, `baseURL`) plus the per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`, so a directive such as `'use server'` can skip barrel files.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the same `BannerMeta` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

### group

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|          |         |
| -------: | :------ |
|    Type: | `Group` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/hooks/
├── pet/
│   ├── useCreatePet.ts
│   └── useGetPets.ts
└── store/
    ├── useCreateOrder.ts
    └── useGetOrderById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Hooks` to the group produces a `petHooks/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key (the operation's first tag) into a folder or identifier name. The result is used as both the subdirectory name under `output.path` and as a suffix when naming aggregate files.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: { group: string }) => string` |
| Default: | `({ group }) => camelCase(group)` |

For `type: 'path'` groups, the default uses the first URL segment as-is instead of camelCasing.

### client

Selects which registered client plugin the generated hooks call. Set `'axios'` to use `@kubb/plugin-axios` or `'fetch'` to use `@kubb/plugin-fetch`. When omitted, the plugin auto-detects the single client plugin in the config, so you only need this option to disambiguate when several client plugins are registered. A client plugin must be registered, since the hooks call its functions.

|          |                      |
| -------: | :------------------- |
|    Type: | `'axios' \| 'fetch'` |

### infinite

Adds infinite-query output for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response. Pass `false` (default) to skip it. Set the [`hooks`](#hooks) option to wrap the output in `useInfiniteQuery`.

|          |                              |
| -------: | :--------------------------- |
|    Type: | `Partial<Infinite> \| false` |
| Default: | `false`                      |

> [!IMPORTANT]
> Infinite output is emitted per operation only when the operation declares a query parameter whose name matches `infinite.queryParam` (default `'id'`). Operations without that parameter keep their regular query output.

With `infinite: false` (the default), a `GET /pets` operation generates `getPetsQueryOptions`. Setting `infinite: {}` adds an extra `getPetsInfiniteQueryOptions` factory that reads the cursor from the response:

::: code-group

```typescript [infinite: false (default)]
export function getPetsQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}
```

```typescript [infinite: {}]
export function getPetsInfiniteQueryOptions(/* ... */) {
  return infiniteQueryOptions({ queryKey, queryFn, initialPageParam, getNextPageParam })
}
```

:::

Which factory you reach for depends on the value:

::: code-group

```typescript [infinite: false (default)]
import { getPetsQueryOptions } from './src/gen/hooks/useGetPets'

const { data } = useQuery(getPetsQueryOptions())
```

```typescript [infinite: {}]
import { getPetsInfiniteQueryOptions } from './src/gen/hooks/useGetPetsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(getPetsInfiniteQueryOptions())
// data.pages holds each fetched page
```

:::

#### infinite.queryParam

Name of the query parameter that holds the page cursor. Kubb passes `pageParam` into this query key.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'id'`   |

#### infinite.initialPageParam

Initial value for `pageParam` on the first fetch.

|          |           |
| -------: | :-------- |
|    Type: | `unknown` |
| Default: | `0`       |

#### infinite.nextParam

Path to the next-page cursor on the response. Supports dot notation (`'pagination.next.id'`) or array form (`['pagination', 'next', 'id']`).

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `string \| Array<string> \| null`   |
| Default: | `null`                              |

#### infinite.previousParam

Path to the previous-page cursor on the response. Supports dot notation (`'pagination.prev.id'`) or array form (`['pagination', 'prev', 'id']`).

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `string \| Array<string> \| null`   |
| Default: | `null`                              |

### suspense

Adds a suspense variant alongside the regular query output. The plugin generates it by default. Set `suspense` to `false` to skip it. Set the [`hooks`](#hooks) option to wrap the output in `useSuspenseQuery`.

Suspense queries throw promises while loading and need a `<Suspense>` boundary in the React tree. TanStack Query v5+ only.

|          |                            |
| -------: | :------------------------- |
|    Type: | `Partial<object> \| false` |
| Default: | `{}`                       |

With `suspense` enabled (the default), a `GET /pets` operation generates both a regular and a suspense factory. Set `suspense: false` to drop the suspense variant:

::: code-group

```typescript [suspense: {} (default)]
export function getPetsQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}

export function getPetsSuspenseQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}
```

```typescript [suspense: false]
export function getPetsQueryOptions(/* ... */) {
  return queryOptions({ queryKey, queryFn })
}
```

:::

Which factory you reach for depends on the value:

::: code-group

```typescript [suspense: {} (default)]
import { getPetsSuspenseQueryOptions } from './src/gen/hooks/useGetPetsSuspense'

// inside a <Suspense> boundary, data is already resolved with no isLoading flag
const { data } = useSuspenseQuery(getPetsSuspenseQueryOptions())
```

```typescript [suspense: false]
import { getPetsQueryOptions } from './src/gen/hooks/useGetPets'

const { data, isLoading, error } = useQuery(getPetsQueryOptions())
```

:::

### query

Decides which operations are treated as queries and how their output is built. The plugin generates a `queryOptions` factory for each matching operation by default. Pass `false` to skip query generation entirely. Set the [`hooks`](#hooks) option to also emit the `useQuery` wrapper.

|          |                           |
| -------: | :------------------------ |
|    Type: | `Partial<Query> \| false` |
| Default: | `{ methods: ['GET'], importPath: '@tanstack/react-query' }` |

#### query.methods

HTTP methods treated as queries. Operations using one of these methods generate a `queryOptions` factory instead of a mutation.

|          |                 |
| -------: | :-------------- |
|    Type: | `Array<string>` |
| Default: | `['get']`       |

#### query.importPath

Module used in the `import { queryOptions } from '...'` statement at the top of every generated file. Point it at your own re-export of TanStack Query, for example a wrapper that injects a default `queryClient`.

|          |                           |
| -------: | :------------------------ |
|    Type: | `string`                  |
| Default: | `'@tanstack/react-query'` |

### queryKey

Builds the `queryKey` for each generated hook. Use it to add a version namespace, key off the operation ID, or match an existing `queryClient.invalidateQueries` strategy. The callback receives the operation `node` and the active `casing`, and returns the array of values that make up the key. When unset, it defaults to Kubb's built-in key builder (`queryKeyTransformer`).

|          |                                                                      |
| -------: | :------------------------------------------------------------------- |
|    Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Default: | `built-in`                                                           |

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

Decides which operations are treated as mutations and how their output is built. The plugin generates a `mutationOptions` factory for each matching operation by default. Set to `false` to skip mutation generation. Set the [`hooks`](#hooks) option to also emit the `useMutation` wrapper.

|          |                              |
| -------: | :--------------------------- |
|    Type: | `Partial<Mutation> \| false` |
| Default: | `{ methods: ['POST', 'PUT', 'PATCH', 'DELETE'], importPath: '@tanstack/react-query' }` |

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these methods generate a `mutationOptions` factory instead of a query. Narrow the list if your API uses one of these methods for reads.

|          |                                      |
| -------: | :----------------------------------- |
|    Type: | `Array<string>`                      |
| Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Module used in the `import { mutationOptions } from '...'` statement at the top of every generated file. Point it at your own wrapper.

|          |                           |
| -------: | :------------------------ |
|    Type: | `string`                  |
| Default: | `'@tanstack/react-query'` |

### mutationKey

Builds the `mutationKey` for each mutation hook. Use it when you batch invalidations or read mutation state with `useMutationState`. The callback receives the same `{ node, casing }` props as `queryKey`. When unset, it defaults to Kubb's built-in key builder (`mutationKeyTransformer`).

|          |                                                                      |
| -------: | :------------------------------------------------------------------- |
|    Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Default: | `built-in`                                                           |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap literal strings in `JSON.stringify(...)`.

### customOptions

Routes every generated hook through your own function that returns extra options, such as `onSuccess`, `onError`, or `select`. Use it to centralize cache invalidation, error toasts, or analytics instead of repeating them at every call site. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

|          |                 |
| -------: | :-------------- |
|    Type: | `CustomOptions` |

#### customOptions.importPath

Module of your custom-options hook. Generated code imports it as a named import, `import { ${name} } from '${importPath}'`. Use a relative path from the generated file or a bare specifier. Required whenever `customOptions` is set.

|          |          |
| -------: | :------- |
|    Type: | `string` |

#### customOptions.name

Exported function name of your custom-options hook. Generated code imports it as a named import, `import { ${name} } from '${importPath}'`, so your module must export this name.

|          |                          |
| -------: | :----------------------- |
|    Type: | `string`                 |
| Default: | `'useCustomHookOptions'` |

### hooks

Controls whether `use*` hook functions are emitted. When set to `false` (the default), the plugin writes only the factory helpers: `queryOptions`, `mutationOptions`, `queryKey`, and `mutationKey`. Set to `true` to also generate `useQuery`, `useSuspenseQuery`, `useInfiniteQuery`, `useSuspenseInfiniteQuery`, and `useMutation` functions.

The factory helpers work with any TanStack Query adapter. You can pass the same `queryOptions` object to `prefetchQuery`, `setQueryData`, and router loaders without wrapping it in a hook.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |
| Default: | `false`   |

::: code-group

```typescript [hooks: false (default)]
// only factories, no use* functions
import { getPetsQueryOptions } from './src/gen/hooks/useGetPets'

// compose manually or pass to router loaders
const options = getPetsQueryOptions()
const data = await queryClient.fetchQuery(options)
```

```typescript [hooks: true]
// factories plus the hook
import { useGetPets } from './src/gen/hooks/useGetPets'

const { data, isLoading } = useGetPets()
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default `resolverReactQuery`. Inside a method, `this` is the full resolver, so you can call `this.core.name(name)` to reuse the built-in name.

|          |                                                              |
| -------: | :----------------------------------------------------------- |
|    Type: | `Partial<ResolverReactQuery> & ThisType<ResolverReactQuery>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.

For example, `resolver: { resolveQueryName(node) { return \`use${this.resolveName(node.name)}Api\` } }` renames every generated query hook.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'GET'` or `'POST'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

`pattern` accepts either a string (exact match) or a `RegExp` for fuzzy matches.

|          |                  |
| -------: | :--------------- |
|    Type: | `Array<Include>` |

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

Pass `include: [{ type: 'tag', pattern: 'pet' }]` to keep only the `pet` tag. Stack entries to narrow further, such as `{ type: 'method', pattern: 'GET' }` with `{ type: 'path', pattern: /^\/pet/ }` for GET operations under `/pet`.

### exclude

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

|          |                  |
| -------: | :--------------- |
|    Type: | `Array<Exclude>` |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

Pass `exclude: [{ type: 'tag', pattern: 'store' }]` to drop the `store` tag, or stack `{ type: 'operationId', pattern: 'deletePet' }` with `{ type: 'method', pattern: 'DELETE' }` to skip one operation and every DELETE.

### override

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. That object accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

|          |                   |
| -------: | :---------------- |
|    Type: | `Array<Override>` |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

For example, `override: [{ type: 'tag', pattern: 'user', options: { suspense: false } }]` drops the suspense hooks for the `user` tag while the rest of the spec keeps the plugin default.
