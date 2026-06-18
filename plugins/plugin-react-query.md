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
dependencies:
  - plugin-ts
  - plugin-client
resources:
  documentation: https://kubb.dev/plugins/plugin-react-query
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/react-query
---

# @kubb/plugin-react-query

`@kubb/plugin-react-query` turns each OpenAPI operation into a [TanStack Query](https://tanstack.com/query) hook for React. Read operations become `useFooQuery`, `useFooSuspenseQuery`, or `useFooInfiniteQuery`. Write operations become `useFooMutation`. Every hook is typed. Query keys, input variables, response data, and error shape all come from the spec.

It needs `@kubb/plugin-ts` for the types and `@kubb/plugin-client` for the HTTP layer.

**See also**

- [TanStack Query](https://tanstack.com/query)

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

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      group: { type: 'tag' },
    }),
  ],
})
```

:::

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

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `(context: { group: string }) => string`  |
| Required: | `false`                                   |
|  Default: | `(ctx) => camelCase(ctx.group)`           |

### client

HTTP client used inside every generated hook. It mirrors a subset of `pluginClient` options. Set these when the hooks need different client behavior than the rest of your app, such as a different base URL or full response objects.

|           |                                                                                |
| --------: | :----------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, paramsCasing? }` |
| Required: | `false`                                                                        |

#### client.importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`. Use it to inject auth headers, add interceptors, change the base URL at runtime, or wrap a different HTTP library (ky, ofetch). Relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) both work. See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath) for the module shape.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!IMPORTANT]
> Generated hooks also import a `Client` type alias. Your module must export `Client`, `RequestConfig`, and `ResponseErrorConfig`, or TypeScript fails the import.

#### client.dataReturnType

Shape of the value returned from each generated client function.

- `'data'` returns only the response body (`response.data`).
- `'full'` returns a discriminated union keyed by HTTP status code. Each member is `{ status: N; data: StatusNType; statusText: string }`. Narrowing on `res.status` narrows `res.data` to the matching response type.

|           |                    |
| --------: | :----------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`            |
|  Default: | `'data'`           |

::: code-group

```typescript ['data' (default)]
const pet = await getPetById(1)
//    ^? Pet
```

```typescript ['full']
const res = await addPet(petData)
if (res.status === 405) {
  res.data // narrowed to AddPetStatus405
}
```

:::

#### client.baseURL

Base URL prepended to every request in the generated client. Use it to point at a different environment (staging, production) than the spec. When omitted, the URL comes from the spec's `servers[0].url`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

#### client.clientType

Style of the HTTP client this plugin imports from `@kubb/plugin-client`.

- `'function'` imports the function client (`getPetById(...)`). Required for query plugins.
- `'class'` generates a wrapper class on top, usable only inside `@kubb/plugin-client`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'function' \| 'class'` |
| Required: | `false`                 |
|  Default: | `'function'`            |

> [!WARNING]
> Query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-svelte-query`, `@kubb/plugin-solid-query`) work only with `clientType: 'function'`. Set `clientType: 'class'` here and the plugin falls back to its own inline function-based client instead of importing from `@kubb/plugin-client`.

#### client.paramsCasing

Renames parameters in the generated client to the chosen casing. Use it alongside the top-level `paramsCasing`. See [`paramsCasing`](#paramscasing).

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### paramsType

How operation parameters (path, query, headers) appear in the generated hook signature.

- `'inline'` (default) makes each parameter a separate positional argument. Compact for one or two params.
- `'object'` wraps every parameter in a single object argument. Easier to read for many params, and the arguments are named at the call site.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

> [!TIP]
> Setting `paramsType: 'object'` also sets `pathParamsType: 'object'`, so call sites stay consistent.

::: code-group

```typescript ['inline' (default)]
await deletePet(42)
```

```typescript ['object']
await deletePet({ petId: 42, headers: { 'X-Api-Key': 'secret' } })
```

:::

### pathParamsType

How URL path parameters appear in the generated function signature. It affects only path params. Query and header params follow `paramsType`.

- `'inline'` (default) makes each path param a positional argument: `getPetById(petId)`.
- `'object'` wraps path params in a single object: `getPetById({ petId })`.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

### paramsCasing

Renames path, query, and header parameters in the generated code to the chosen casing. The HTTP request still uses the original names from the spec, and Kubb writes the mapping.

- `'camelcase'` turns `pet_id` and `X-Api-Key` into `petId` and `xApiKey` in your TypeScript code. The runtime URL still uses `/pet/{pet_id}`, and the header is still sent as `X-Api-Key`.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

> [!IMPORTANT]
> Set the same `paramsCasing` on every plugin that touches parameters (`@kubb/plugin-ts`, `@kubb/plugin-client`, `@kubb/plugin-react-query`, `@kubb/plugin-faker`, `@kubb/plugin-mcp`). Mismatched casing breaks the generated type chain.

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

### infinite

Enables `useInfiniteQuery` hooks for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response. Pass `false` (default) to skip infinite query generation.

|           |                     |
| --------: | :------------------ |
|     Type: | `Infinite \| false` |
| Required: | `false`             |
|  Default: | `false`             |

::: code-group

```typescript twoslash [Cursor pagination]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      infinite: {
        queryParam: 'cursor',
        initialPageParam: null,
        nextParam: 'pagination.next.cursor',
        previousParam: 'pagination.prev.cursor',
      },
    }),
  ],
})
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

#### infinite.cursorParam

> [!WARNING]
> `cursorParam` is deprecated. Use `nextParam` and `previousParam` for finer pagination control.

Path to the cursor field on the response. Leave it `null` when the cursor is not known.

|           |                  |
| --------: | :--------------- |
|     Type: | `string \| null` |
| Required: | `false`          |
|  Default: | `null`           |

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

### query

Configures the query hooks. The plugin generates them by default. Pass `false` to skip the hooks and emit only `queryOptions(...)` helpers, so you can call `useQuery` yourself in app code.

|           |         |
| --------: | :------ |
|     Type: | `Query` |
| Required: | `false` |
|  Default: | `{}`    |

#### query.methods

HTTP methods treated as queries. Operations using one of these methods generate a `useQuery`-style hook (or a `queryOptions` helper) instead of a mutation.

|           |                     |
| --------: | :------------------ |
|     Type: | `Array<HttpMethod>` |
| Required: | `false`             |
|  Default: | `['get']`           |

::: code-group

```typescript twoslash [Allow HEAD as a query method]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      query: { methods: ['get', 'head'] },
    }),
  ],
})
```

:::

#### query.importPath

Module used in the `import { useQuery } from '...'` statement at the top of every generated hook file. Point it at your own re-export of TanStack Query, for example a wrapper that injects a default `queryClient`.

|           |                           |
| --------: | :------------------------ |
|     Type: | `string`                  |
| Required: | `false`                   |
|  Default: | `'@tanstack/react-query'` |

### queryKey

Builds the `queryKey` for each generated hook. Use it to add a version namespace, key off the operation ID, or match an existing `queryClient.invalidateQueries` strategy.

The callback receives a `node` and the active `casing`. `node` is the operation's AST node, exposing `operationId`, `tags`, `method`, `path`, `parameters`, and `requestBody`. `casing` is `'camelcase'` when `paramsCasing` is set, otherwise `undefined`. Return the array of values that make up the key.

|           |                                                                       |
| --------: | :-------------------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Required: | `false`                                                               |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any string you want emitted as a literal in `JSON.stringify(...)`.

#### Keys from tags and path parameters

Build a key from the operation's first tag plus its path parameters. For a `GET /user/{username}` operation with the `user` tag, this generates:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      queryKey: ({ node }) => {
        const tags = node.tags.map((tag) => JSON.stringify(tag))
        const pathParams = node.parameters.filter((param) => param.in === 'path').map((param) => param.name)
        return [...tags, ...pathParams]
      },
    }),
  ],
})
```

```typescript [Generated output]
export const getUserByNameQueryKey = ({ username }: { username: GetUserByNamePathParams['username'] }) => ['user', username] as const
```

#### Add a version prefix

Prepend a fixed version segment in front of the path:

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      queryKey: ({ node }) => [JSON.stringify('v5'), JSON.stringify(node.path)],
    }),
  ],
})
```

```typescript [Generated output]
export const findPetsByTagsQueryKey = (params?: FindPetsByTagsQueryParams) => ['v5', '/pet/findByTags'] as const
```

### suspense

Adds `useSuspenseQuery` hooks alongside the regular `useQuery` ones. The plugin generates these by default. Set `suspense` to `false` to skip them.

Suspense queries throw promises while loading and need a `<Suspense>` boundary in the React tree. TanStack Query v5+ only.

|           |                   |
| --------: | :---------------- |
|     Type: | `object \| false` |
| Required: | `false`           |
|  Default: | `{}`              |

### mutation

Configures the mutation hooks. The plugin generates them by default. Set to `false` to skip mutation generation.

|           |            |
| --------: | :--------- |
|     Type: | `Mutation` |
| Required: | `false`    |
|  Default: | `{}`       |

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these methods generate a `useMutation`-style hook instead of a query. Narrow the list if your API uses one of these methods for reads.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<HttpMethod>`                  |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

::: code-group

```typescript twoslash [Treat only POST and PUT as mutations]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      mutation: { methods: ['post', 'put'] },
    }),
  ],
})
```

:::

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

Routes every generated hook through your own function that returns extra options (`onSuccess`, `onError`, `select`). Use it to centralize cache invalidation, error toasts, or analytics instead of repeating them at every call site. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

|           |                 |
| --------: | :-------------- |
|     Type: | `CustomOptions` |
| Required: | `false`         |

#### Centralized cache invalidation

```typescript [src/useCustomHookOptions.ts]
import { useQueryClient, type QueryClient } from '@tanstack/react-query'
import type { HookOptions } from '../gen/hookOptions'
import { getUserByNameQueryKey } from '../gen/hooks/user/useGetUserByNameHook'

function getCustomHookOptions({ queryClient }: { queryClient: QueryClient }): Partial<HookOptions> {
  return {
    useUpdatePetHook: {
      onSuccess: () => {
        void queryClient.invalidateQueries({ queryKey: ['pet'] })
      },
    },
    useUpdateUserHook: {
      onSuccess: (_data, variables) => {
        void queryClient.invalidateQueries({
          queryKey: getUserByNameQueryKey({ username: variables.username }),
        })
      },
    },
  }
}

export function useCustomHookOptions<T extends keyof HookOptions>({ hookName }: { hookName: T; operationId: string }): HookOptions[T] {
  const queryClient = useQueryClient()
  const customOptions = getCustomHookOptions({ queryClient })
  return customOptions[hookName] ?? {}
}
```

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

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the media type of the request body.

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

::: code-group

```typescript twoslash [Only the pet tag]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript twoslash [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      include: [
        { type: 'method', pattern: 'GET' },
        { type: 'path', pattern: /^\/pet/ },
      ],
    }),
  ],
})
```

:::

### exclude

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

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

::: code-group

```typescript twoslash [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript twoslash [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      exclude: [
        { type: 'operationId', pattern: 'deletePet' },
        { type: 'method', pattern: 'DELETE' },
      ],
    }),
  ],
})
```

:::

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

::: code-group

```typescript twoslash [Skip query hooks for the user tag]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { query: false },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                              |
| --------: | :----------------------------------------------------------- |
|     Type: | `Partial<ResolverReactQuery> & ThisType<ResolverReactQuery>` |
| Required: | `false`                                                      |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript twoslash [Add an Api prefix to every name]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      resolver: {
        resolveName(name) {
          return `Api${this.default(name, 'function')}`
        },
      },
    }),
  ],
})
```

### generators

Adds custom generators that run next to the built-in ones. Each generator can emit extra files or post-process existing ones using the plugin's AST and options. Use it for output the plugin does not produce, such as a custom client wrapper or a metadata file. See [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<Generator<PluginReactQuery>>` |
| Required: | `false`                              |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript twoslash [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
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

```typescript twoslash [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      macros: [
        {
          name: 'prefix-operation-id',
          operation(node) {
            return { ...node, operationId: `api_${node.operationId}` }
          },
        },
      ],
    }),
  ],
})
```

:::

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-client`](/plugins/plugin-client)

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginReactQuery({
      output: { path: './hooks' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Hooks`,
      },
      client: { dataReturnType: 'full' },
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

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md)
