---
layout: doc
title: Kubb Vue Query Plugin
description: Generate TanStack Query composables for Vue (useQuery, useMutation,
  useInfiniteQuery) from OpenAPI.
outline: 2
kind: plugin
id: plugin-vue-query
name: Vue Query
category: framework
type: official
npmPackage: "@kubb/plugin-vue-query"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-vue-query
featured: false
icon:
  light: https://kubb.dev/feature/tanstack.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - vue-query
  - tanstack-query
  - vue
  - composables
  - data-fetching
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-client
resources:
  documentation: https://kubb.dev/plugins/plugin-vue-query
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-vue-query/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/vue-query
---

# @kubb/plugin-vue-query

`@kubb/plugin-vue-query` turns each OpenAPI operation into a [TanStack Query](https://tanstack.com/query) composable for Vue. Read operations become `useFooQuery` and optionally `useFooInfiniteQuery`. Write operations become `useFooMutation`. Every composable is typed. Query keys, input variables, response data, and error shape all come from the spec.

It needs `@kubb/plugin-ts` for the types. The HTTP client comes from `@kubb/plugin-client`, which the plugin bundles into the output.

Each composable takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

**See also**

- [TanStack Query for Vue](https://tanstack.com/query/latest/docs/framework/vue/overview)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-vue-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-vue-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-vue-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-vue-query@beta
```

:::

## Options

### output

Where the generated composables are written and how they are exported.

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

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      output: { path: './hooks' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── hooks/
        ├── useGetPetByIdQuery.ts
        └── useAddPetMutation.ts
```

:::

#### output.mode

How the plugin groups its code into files.

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
- `false` skips the barrel. The plugin's files are also left out of the root `index.ts`.

|           |                                                         |
| --------: | :------------------------------------------------------ |
|     Type: | `{ type: 'named' \| 'all', nested?: boolean } \| false` |
| Required: | `false`                                                 |
|  Default: | `{ type: 'named' }`                                     |

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode`.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode`.

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

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      group: { type: 'tag' },
    }),
  ],
})
```

```text [Resulting tree]
src/gen/hooks/
├── pet/
│   ├── useAddPetMutation.ts
│   └── useGetPetByIdQuery.ts
└── store/
    ├── usePlaceOrderMutation.ts
    └── useGetInventoryQuery.ts
```

:::

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

Operations with no tag go in a default group.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that turns a group key (the operation's first tag) into a folder name.

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### client

HTTP client used inside every generated composable. Each composable calls this client to run the request. It mirrors a subset of `pluginClient` options. Set these when the Vue composables need different client behavior than the rest of your app.

|           |                                                                              |
| --------: | :--------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL? }` |
| Required: | `false`                                                                      |

#### client.client

HTTP client that the generated composables call. `'axios'` imports from `@kubb/plugin-client/clients/axios` and needs `axios` at runtime. `'fetch'` imports from `@kubb/plugin-client/clients/fetch` and uses the global `fetch`. Set `client.importPath` to point at a custom module instead, which ignores `client.client`.

|           |                      |
| --------: | :------------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`              |
|  Default: | `'axios'`            |

#### client.importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`. Use it to inject auth headers, add interceptors, set the base URL at runtime, or wrap another HTTP library. Both relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) work.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!IMPORTANT]
> Generated composables also import a `Client` type alias. Your module must export `Client`, `RequestConfig`, and `ResponseErrorConfig`, or TypeScript fails the import. See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath).

::: code-group

```typescript [Wire up a custom client]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      client: { importPath: './src/client.ts' },
    }),
  ],
})
```

:::

#### client.dataReturnType

Shape of the value returned from each generated client function.

- `'data'` returns only the response body (`response.data`).
- `'full'` returns a discriminated union keyed by HTTP status code. Narrowing on `res.status` also narrows `res.data` to the matching response type.

|           |                    |
| --------: | :----------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`            |
|  Default: | `'data'`           |

#### client.baseURL

Base URL prepended to every request URL in the generated client. When omitted, the URL comes from the spec's `servers[0].url`. Set it to point the client at a different environment than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

#### client.clientType

Style of the HTTP client this plugin imports from `@kubb/plugin-client`.

- `'function'` imports the function client (`getPetById(...)`). Required for this plugin.
- `'class'` also generates a wrapper class, but it only works inside `@kubb/plugin-client`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'function' \| 'class'` |
| Required: | `false`                 |
|  Default: | `'function'`            |

> [!WARNING]
> Vue Query works only with `clientType: 'function'`. If you set `clientType: 'class'`, the plugin falls back to generating its own inline function client instead of importing from `@kubb/plugin-client`.

### parser

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`.

- `false` (default) does no validation. The client returns the response cast to the generated type.
- `'zod'` validates response bodies only.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction. `request` validates the request body and query parameters before the call. `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is set to `'zod'`.

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

::: code-group

```typescript [Validate responses with Zod]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginVueQuery({
      parser: 'zod',
    }),
  ],
})
```

```typescript [Validate request and response]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginVueQuery({
      parser: { request: 'zod', response: 'zod' },
    }),
  ],
})
```

:::

### infinite

Enables `useInfiniteQuery` composables for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response. Pass `false` (default) to skip.

|           |                            |
| --------: | :------------------------- |
|     Type: | `Partial<Infinite> \| false` |
| Required: | `false`                    |
|  Default: | `false`                    |

#### infinite.queryParam

Name of the query parameter that holds the page cursor.

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

Path to the previous-page cursor on the response. Supports dot notation or array form.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `string \| string[] \| null` |
| Required: | `false`                      |
|  Default: | `null`                       |

#### infinite.cursorParam

Path to the cursor field on the response. Leave it unset when the cursor is not known.

|           |                  |
| --------: | :--------------- |
|     Type: | `string \| null` |
| Required: | `false`          |
|  Default: | `null`           |

> [!WARNING]
> `cursorParam` is deprecated. Use `nextParam` and `previousParam` for finer pagination control.

### query

Configures the query composables. Pass `false` to skip composable generation and emit only `queryOptions(...)` helpers.

|           |                         |
| --------: | :---------------------- |
|     Type: | `Partial<Query> \| false` |
| Required: | `false`                 |

#### query.methods

HTTP methods treated as queries. Operations using one of these generate a `useQuery`-style composable (or `queryOptions` helper) instead of a mutation. Add a method such as `'head'` only when your API uses it for cache-friendly reads.

|           |                     |
| --------: | :------------------ |
|     Type: | `Array<HttpMethod>` |
| Required: | `false`             |
|  Default: | `['get']`           |

::: code-group

```typescript [Allow HEAD as a query method]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      query: { methods: ['get', 'head'] },
    }),
  ],
})
```

:::

#### query.importPath

Module specifier used in the `import { useQuery } from '...'` statement at the top of every generated composable file. Use it to route through your own wrapper.

|           |                         |
| --------: | :---------------------- |
|     Type: | `string`                |
| Required: | `false`                 |
|  Default: | `'@tanstack/vue-query'` |

### queryKey

Builds the `queryKey` for each generated composable. Use it to add a version namespace, swap to operation IDs, or shape keys to match an existing invalidation strategy. The callback receives the operation `node`.

|           |                                                            |
| --------: | :--------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing }) => Array<unknown>` |
| Required: | `false`                                                    |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

::: code-group

```typescript [Prepend a version prefix]
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: ({ node }) => {
        const hasQueryParams = node.parameters.some((param) => param.in === 'query')
        const defaultKeys = [`{ url: ${JSON.stringify(node.path)} }`, hasQueryParams ? '...(params ? [params] : [])' : null].filter(Boolean)
        return [JSON.stringify('v5'), ...defaultKeys]
      },
    }),
  ],
})
```

```typescript [Key from operationId]
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: ({ node }) => [JSON.stringify(node.operationId)],
    }),
  ],
})
```

:::

### mutation

Configures the mutation composables. Pass `false` to skip mutation generation.

|           |                            |
| --------: | :------------------------- |
|     Type: | `Partial<Mutation> \| false` |
| Required: | `false`                    |

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these generate a `useMutation`-style composable instead of a query. Narrow the list if your API uses one of these methods for reads.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<HttpMethod>`                  |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

::: code-group

```typescript [Treat only POST and PUT as mutations]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      mutation: { methods: ['post', 'put'] },
    }),
  ],
})
```

:::

#### mutation.importPath

Module specifier used in the `import { useMutation } from '...'` statement at the top of every generated composable file.

|           |                         |
| --------: | :---------------------- |
|     Type: | `string`                |
| Required: | `false`                 |
|  Default: | `'@tanstack/vue-query'` |

### mutationKey

Builds the `mutationKey` for each mutation composable. Useful when you batch invalidations or read mutation state through `useMutationState`. The callback receives the operation `node`.

|           |                                                            |
| --------: | :--------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing }) => Array<unknown>` |
| Required: | `false`                                                    |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request or response media type.

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

```typescript [Only the pet tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
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

```typescript [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      exclude: [{ type: 'tag', pattern: 'store' }],
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

```typescript [Return full responses for the user tag only]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
      client: { dataReturnType: 'data' },
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { client: { dataReturnType: 'full' } },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated composables and files. Override only the methods you want to change. Anything you omit falls back to the default resolver. Inside a method, `this` is the full resolver.

|           |                             |
| --------: | :-------------------------- |
|     Type: | `Partial<ResolverVueQuery>` |
| Required: | `false`                     |

### macros

A list of [macros](/docs/5.x/concepts/macros) applied to each operation node before code is printed. Use it to rewrite operation IDs, tags, or descriptions across the output.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

## Dependencies

This plugin depends on [`@kubb/plugin-ts`](/plugins/plugin-ts), so add it to the plugins list. The composables call an HTTP client from `@kubb/plugin-client`, which the plugin bundles into the output, so a separate `@kubb/plugin-client` entry is optional.

Set `parser` to `'zod'` and the plugin also depends on [`@kubb/plugin-zod`](/plugins/plugin-zod), which then has to be in the plugins list.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginVueQuery({
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
      },
      query: {
        methods: ['get'],
        importPath: '@tanstack/vue-query',
      },
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-vue-query/CHANGELOG.md)
