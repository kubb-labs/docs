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

> [!TIP]
> Reference: [TanStack Query](https://tanstack.com/query) for cache, retries, and devtools.

# @kubb/plugin-react-query

Generate one [TanStack Query](https://tanstack.com/query) hook per OpenAPI operation. Queries become `useFooQuery`, `useFooSuspenseQuery`, or `useFooInfiniteQuery`, and mutations become `useFooMutation`. Each hook is typed. Query keys, input variables, response data, and error shape all come from the spec.

Pairs with `@kubb/plugin-client` for the HTTP layer and `@kubb/plugin-ts` for types.

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

Folder where the plugin writes its generated code, resolved against the global `output.path` set on `defineConfig`. To put everything in one file instead, set `output.mode: 'file'` and point `path` at a target file including its extension (e.g. `'types.ts'`).

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
- `false` skips the barrel. The plugin's files are also excluded from the root `index.ts`.

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

```typescript ['all' → src/gen/types/index.ts]
// output: { barrel: { type: 'all' } }
export * from './Pet'
export * from './Store'
```

```text [nested → generated tree]
// output: { barrel: { type: 'named', nested: true } }
src/gen/types/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports Pet, Store, ...
│   └── Pet.ts
└── store/
    ├── index.ts
    └── Store.ts
```

```text [false → result]
// output: { barrel: false }
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text prepended to every generated file, for license headers, lint disables, or `@ts-nocheck` directives. Pass a string for a static banner, or a function to compute it from each file's `RootNode` (the AST root holding path, schema, and operation context).

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

Text appended to every generated file. Mirrors `banner`, for closing comments, re-enabling lint rules, or marker lines. Pass a string or a function that receives the file's `RootNode` and returns the footer text.

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

Lets the plugin overwrite hand-written files that share a name with a generated file.

- `false` (default): skips a file that already exists and is not marked as generated, protecting manual edits.
- `true`: overwrites any file at the target path, including hand-written ones.

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

Splits generated files into subfolders by the operation's first tag, so each tag gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

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

Pass `group.name` to customize the folder name, for example `name: ({ group }) => \`${group}Controller\`` to keep the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the first tag on the operation and uses it as the group key. Operations without a tag land in a default group.
- `'path'` uses the first segment of the operation's URL, so `/pet/findByStatus` groups under `pet`.

|           |                  |
| --------: | :--------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`           |

> [!NOTE]
> `Required: true*` is conditional. It is only required when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder name from a group key. The default camelCases the tag for `tag` groups and takes the first path segment for `path` groups.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                  |
|  Default: | `(ctx) => camelCase(ctx.group)`          |

### client

HTTP client used inside every generated hook. Mirrors a subset of `pluginClient` options; set these when the React Query hooks need different client behavior than the rest of your app (a different base URL or full response objects, for example).

|           |                                                                          |
| --------: | :----------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, bundle?, paramsCasing? }` |
| Required: | `false`                                                                                 |

#### client.importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`, letting you inject auth headers, add interceptors, change the base URL at runtime, or wrap a different HTTP library (ky, ofetch, ...). Both relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) work. See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath) for the full module shape and a worked example.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!IMPORTANT]
> Generated hooks also import a `Client` type alias, so your module must export `Client`, `RequestConfig`, and `ResponseErrorConfig`, or TypeScript fails the import.

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
export async function getPetById<TData>(petId: GetPetByIdPathParams): Promise<ResponseConfig<TData>['data']> {
  // ...
}
```

```typescript [usage.ts]
const pet = await getPetById(1)
//    ^? Pet
```

```typescript ['full']
export async function addPet(data: AddPetData, config = {}) {
  const res = await request<AddPetStatus200 | AddPetStatus405, ...>(...)
  return res as
    | { status: 200; data: AddPetStatus200; statusText: string }
    | { status: 405; data: AddPetStatus405; statusText: string }
}
```

```typescript [usage.ts]
const res = await addPet(petData)
if (res.status === 405) {
  res.data // narrowed to AddPetStatus405
}
```

:::

#### client.baseURL

Base URL prepended to every request URL in the generated client, for pointing at a different environment (staging, production) than the spec. When omitted, the URL comes from the spec's `servers[0].url` (or whichever index the adapter reads).

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

#### client.clientType

Style of the HTTP client that this plugin imports from `@kubb/plugin-client`.

- `'function'` imports the function client (`getPetById(...)`). Required for query plugins.
- `'class'` also generates a wrapper class on top, but it is only usable inside `@kubb/plugin-client`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'function' \| 'class'` |
| Required: | `false`                 |
|  Default: | `'function'`            |

> [!WARNING]
> Query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-svelte-query`, `@kubb/plugin-solid-query`) work only with `clientType: 'function'`. If you set `clientType: 'class'` here, the plugin falls back to generating its own inline function-based client instead of importing from `@kubb/plugin-client`.

#### client.bundle

Copies the HTTP client runtime into the generated output, so the consuming app does not need `@kubb/plugin-client` at runtime.

- `false` (default) makes generated files import from `@kubb/plugin-client/clients/{client}`. Smaller diff, but the package must be a runtime dependency.
- `true` makes Kubb write a `.kubb/client.ts` with the client implementation and generated code imports from there, so the project no longer pulls `@kubb/plugin-client` at runtime.
- Setting `client.importPath` overrides both behaviors and uses your custom client instead.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### paramsType

How operation parameters (path, query, headers) are exposed in the generated function signature.

- `'inline'` (default) makes each parameter a separate positional argument. Compact for operations with one or two params.
- `'object'` wraps every parameter in a single object argument. Easier to read for operations with many params, and the arguments are named at the call site.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

> [!TIP]
> Setting `paramsType: 'object'` implicitly sets `pathParamsType: 'object'` as well, so call sites are consistent.

::: code-group

```typescript ['inline' (default)]
export async function deletePet(petId: DeletePetPathParams['petId'], headers?: DeletePetHeaderParams, config: Partial<RequestConfig> = {}) {
  // ...
}
```

```typescript [Caller]
await deletePet(42)
```

```typescript ['object']
export async function deletePet(
  {
    petId,
    headers,
  }: {
    petId: DeletePetPathParams['petId']
    headers?: DeletePetHeaderParams
  },
  config: Partial<RequestConfig> = {},
) {
  // ...
}
```

```typescript [Caller]
await deletePet({ petId: 42, headers: { 'X-Api-Key': 'secret' } })
```

:::

### paramsCasing

Renames path, query, and header parameters in the generated client to the chosen casing. The HTTP request still uses the original names from the OpenAPI spec, and Kubb writes the mapping.

- `'camelcase'` turns `pet_id` and `X-Api-Key` into `petId` and `xApiKey` in your TypeScript code. The runtime URL still uses `/pet/{pet_id}` and the header is still sent as `X-Api-Key`.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

> [!TIP]
> Callers write friendly camelCase names. The generated client maps them back to whatever the API expects (snake_case path params, kebab-case headers, ...).

> [!IMPORTANT]
> Set the same `paramsCasing` on every plugin that touches operation parameters (`@kubb/plugin-ts`, `@kubb/plugin-client`, `@kubb/plugin-react-query`, `@kubb/plugin-faker`, `@kubb/plugin-mcp`). Mismatched casing causes type errors between generated layers.

::: code-group

```typescript [With paramsCasing: 'camelcase']
// Function takes camelCase parameters
export async function deletePet(petId: DeletePetPathParams['petId'], headers?: DeletePetHeaderParams, config: Partial<RequestConfig> = {}) {
  // ...mapped back to the original API name internally
  const pet_id = petId

  return client({
    method: 'DELETE',
    url: `/pet/${pet_id}`,
    ...config,
  })
}
```

```typescript [Caller]
await deletePet(42)
```

```typescript [Without paramsCasing]
// Function parameters mirror the OpenAPI spec
export async function deletePet(pet_id: DeletePetPathParams['pet_id'], headers?: DeletePetHeaderParams, config: Partial<RequestConfig> = {}) {
  return client({
    method: 'DELETE',
    url: `/pet/${pet_id}`,
    ...config,
  })
}
```

:::

### pathParamsType

How URL path parameters appear in the generated function signature. This affects only path params. Query and header params follow `paramsType`.

- `'inline'` (default) makes each path param a positional argument: `getPetById(petId)`.
- `'object'` wraps path params in a single object: `getPetById({ petId })`.

|           |                        |
| --------: | :--------------------- |
|     Type: | `'object' \| 'inline'` |
| Required: | `false`                |
|  Default: | `'inline'`             |

::: code-group

```typescript ['inline' (default)]
export async function getPetById(petId: GetPetByIdPathParams) {
  // ...
}
```

```typescript ['object']
export async function getPetById({ petId }: GetPetByIdPathParams) {
  // ...
}
```

:::

### parser

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`.

- `false` (default): no validation. The client returns the response cast to the generated TypeScript type without parsing.
- `'zod'`: validates response bodies only (backward-compatible shorthand).
- `{ request?: 'zod', response?: 'zod' }`: opt in per direction. `request` validates the request body and query parameters before the call. `response` validates the response body after.

Requires `@kubb/plugin-zod` in the plugins list when either direction is set to `'zod'`.

With `coercion` enabled in `@kubb/plugin-zod`, request-side parsing also normalizes types (`z.coerce.number()` converts a stringified number from a form field).

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

::: code-group

```typescript [Validate responses with Zod]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginClient({
      parser: 'zod',
    }),
  ],
})
```

```typescript [Validate both request and response with Zod]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginClient({
      parser: { request: 'zod', response: 'zod' },
    }),
  ],
})
```

:::

### infinite

Enables `useInfiniteQuery` hooks for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response. Pass `false` (default) to skip infinite query generation.

|           |                     |
| --------: | :------------------ |
|     Type: | `Infinite \| false` |
| Required: | `false`             |
|  Default: | `false`             |

```typescript [Infinite type]
type Infinite =
  | {
      /** Query-param key used as the page cursor. Defaults to `'id'`. */
      queryParam?: string
      /** @deprecated Use `nextParam` / `previousParam` instead. */
      cursorParam?: string | null
      /** Path to the next-page cursor in the response. Dot or array form. */
      nextParam?: string | string[] | null
      /** Path to the previous-page cursor in the response. Dot or array form. */
      previousParam?: string | string[] | null
      /** Value of `pageParam` for the first page. Defaults to `0`. */
      initialPageParam?: unknown
    }
  | false
```

::: code-group

```typescript [Cursor pagination]
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

Name of the query parameter that holds the page cursor (Kubb passes `pageParam` into this query key).

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

Configures the query hooks. The plugin generates them by default. Pass `false` to skip the hooks and emit only `queryOptions(...)` helpers, useful when you want to call `useQuery` yourself in app code.

|           |         |
| --------: | :------ |
|     Type: | `Query` |
| Required: | `false` |
|  Default: | `{}`    |

```typescript [Query type]
type Query =
  | {
      methods: Array<HttpMethod>
      importPath?: string
    }
  | false
```

#### query.methods

HTTP methods treated as queries. Operations using one of these methods generate a `useQuery`-style hook (or `queryOptions` helper) instead of a mutation.

Defaults to `['get']`. Add other methods (for example `'head'`) only when your API uses them for cache-friendly reads.

|           |                     |
| --------: | :------------------ |
|     Type: | `Array<HttpMethod>` |
| Required: | `false`             |
|  Default: | `['get']`           |

::: code-group

```typescript [Allow HEAD as a query method]
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

Module specifier used in the `import { useQuery } from '...'` statement at the top of every generated hook file. Use this to point at your own re-export of TanStack Query (for example a wrapper that injects a default `queryClient`).

|           |                           |
| --------: | :------------------------ |
|     Type: | `string`                  |
| Required: | `false`                   |
|  Default: | `'@tanstack/react-query'` |

### queryKey

Builds the `queryKey` for each generated hook. Use this to add a version namespace, key off the operation ID, or match an existing `queryClient.invalidateQueries` strategy.

The callback receives a `node` and the active `casing`. `node` is the operation's AST node, exposing `operationId`, `tags`, `method`, `path`, `parameters`, and `requestBody`. `casing` is `'camelcase'` when `paramsCasing` is set, otherwise `undefined`. Return the array of values that make up the key.

|           |                                                                       |
| --------: | :-------------------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Required: | `false`                                                               |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any string you want emitted as a literal in `JSON.stringify(...)`.

#### Keys from tags and path parameters

Build a key from the operation's first tag plus its path parameters. For a `GET /user/{username}` operation with the `user` tag, this generates:

```typescript
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

```typescript
export const getUserByNameQueryKey = ({ username }: { username: GetUserByNamePathParams['username'] }) => ['user', username] as const
```

#### Key from operationId

Use the operation ID as the only key to keep the key as small as possible.

```typescript
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginReactQuery({
      queryKey: ({ node }) => [JSON.stringify(node.operationId)],
    }),
  ],
})
```

#### Add a version prefix

Prepend a fixed version segment in front of the path:

```typescript
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

```typescript
export const findPetsByTagsQueryKey = (params?: FindPetsByTagsQueryParams) => ['v5', '/pet/findByTags'] as const
```

### suspense

Adds `useSuspenseQuery` hooks alongside the regular `useQuery` ones. The plugin generates these hooks by default. Set `suspense` to `false` to skip them.

Suspense queries throw promises while loading and require a `<Suspense>` boundary in the React tree. TanStack Query v5+ only.

|           |                   |
| --------: | :---------------- |
|     Type: | `object \| false` |
| Required: | `false`           |
|  Default: | `{}`              |

### mutation

Configures mutation hooks. The plugin generates them by default. Set to `false` to skip mutation generation entirely.

|           |            |
| --------: | :--------- |
|     Type: | `Mutation` |
| Required: | `false`    |
|  Default: | `{}`       |

```typescript [Mutation type]
type Mutation =
  | {
      methods: Array<HttpMethod>
      importPath?: string
    }
  | false
```

#### mutation.methods

HTTP methods treated as mutations. Operations using one of these methods generate a `useMutation`-style hook instead of a query.

Defaults to `['post', 'put', 'patch', 'delete']`. Narrow the list if your API uses one of these methods for reads.

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<HttpMethod>`                  |
| Required: | `false`                              |
|  Default: | `['post', 'put', 'patch', 'delete']` |

::: code-group

```typescript [Treat only POST and PUT as mutations]
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

Module specifier used in the `import { useMutation } from '...'` statement at the top of every generated hook file. Useful for routing through your own wrapper.

|           |                           |
| --------: | :------------------------ |
|     Type: | `string`                  |
| Required: | `false`                   |
|  Default: | `'@tanstack/react-query'` |

### mutationKey

Builds the `mutationKey` for each mutation hook. Use it when you batch invalidations or read mutation state via `useMutationState`. The callback receives the same `{ node, casing }` props as `queryKey`.

|           |                                                                       |
| --------: | :-------------------------------------------------------------------- |
|     Type: | `(props: { node: OperationNode; casing?: 'camelcase' }) => unknown[]` |
| Required: | `false`                                                               |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap literal strings in `JSON.stringify(...)`.

### customOptions

Wires every generated hook through a user-supplied function that returns extra options (`onSuccess`, `onError`, `select`, ...), to centralize cache invalidation, error toasts, or analytics instead of repeating them at every call site. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

|           |                 |
| --------: | :-------------- |
|     Type: | `CustomOptions` |
| Required: | `false`         |

```typescript [CustomOptions type]
type CustomOptions = {
  importPath: string
  name?: string
}
```

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
    useDeletePetHook: {
      onSuccess: (_data, variables) => {
        void queryClient.invalidateQueries({ queryKey: ['pet', variables.pet_id] })
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

The same wrapper centralizes other concerns: return `onError` handlers from `getCustomHookOptions` to report errors or show toasts app-wide.

#### customOptions.importPath

Module specifier of your custom-options hook. The generated code imports it as a named import, `import { ${name} } from '${importPath}'`. Use a relative path from the generated file or a bare specifier.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

#### customOptions.name

Exported function name of your custom-options hook. The generated code imports it as a named import, `import { ${name} } from '${importPath}'`, so your module must export this name.

|           |                          |
| --------: | :----------------------- |
|     Type: | `string`                 |
| Required: | `false`                  |
|  Default: | `'useCustomHookOptions'` |

### include

Restricts generation to operations that match at least one entry in the list. Anything else is skipped. Each entry filters by one of:

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

Skips any operation that matches at least one entry in the list, the opposite of `include`. Entries take the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`) and `pattern` (string or `RegExp`) as `include`. When both are set, `exclude` wins.

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

Applies a different set of plugin options to operations that match a pattern, for the handful of endpoints that need different treatment. Each entry takes the same `type` and `pattern` as `include`/`exclude`, plus an `options` object that overrides the plugin's options for matched operations. Entries evaluate top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

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

```typescript [Skip query hooks for the user tag]
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

### generators

Adds custom generators that run alongside the built-in ones, each emitting extra files or post-processing existing ones using the plugin's AST and options. Use it for output the plugin does not produce by default (a custom client wrapper, an extra index, a metadata file). See [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                      |
| --------: | :----------------------------------- |
|     Type: | `Array<Generator<PluginReactQuery>>` |
| Required: | `false`                              |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### resolver

Overrides how the plugin builds names and paths for generated files and symbols, to add prefixes, suffixes, or a different casing strategy without forking the plugin. Override only the methods you want to change; anything you omit (or that returns `null`/`undefined`) falls back to the default resolver. Inside each method, `this` is bound to the full resolver, so you can call `this.default(name, 'function')` to delegate to the built-in version.

|           |                                                              |
| --------: | :----------------------------------------------------------- |
|     Type: | `Partial<ResolverReactQuery> & ThisType<ResolverReactQuery>` |
| Required: | `false`                                                      |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript [Add an Api prefix to every name]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      resolver: {
        resolveName(name) {
          return `Api${this.default(name, 'function')}`
        },
      },
    }),
  ],
})
```

Each plugin ships with a default resolver:

| Plugin                 | Default resolver  |
| ---------------------- | ----------------- |
| `@kubb/plugin-ts`      | `resolverTs`      |
| `@kubb/plugin-zod`     | `resolverZod`     |
| `@kubb/plugin-faker`   | `resolverFaker`   |
| `@kubb/plugin-cypress` | `resolverCypress` |
| `@kubb/plugin-msw`     | `resolverMsw`     |
| `@kubb/plugin-mcp`     | `resolverMcp`     |
| `@kubb/plugin-client`  | `resolverClient`  |

### macros

Rewrite AST nodes before they are printed to source code, to rewrite operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (e.g. `schema`, `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it untouched. Callbacks you omit keep the default behavior, and macros run in order so a later one sees the output of an earlier one.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

```typescript [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
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

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-client`](/plugins/plugin-client)

## Example

::: code-group

```typescript [kubb.config.ts]
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
