---
layout: doc
title: Kubb Vue Query Plugin
description: Generate TanStack Query composables for Vue (useQuery, useMutation,
  useInfiniteQuery) from OpenAPI.
outline: 2
kind: plugin
id: plugin-vue-query
header: plugin
---

> [!TIP]
> Reference: [TanStack Query for Vue](https://tanstack.com/query/latest/docs/framework/vue/overview) for cache, retries, and devtools.

# @kubb/plugin-vue-query

Generate one [TanStack Query](https://tanstack.com/query) composable per OpenAPI operation, ready to use inside Vue's Composition API. Queries become `useFooQuery` (and optionally `useFooInfiniteQuery`); mutations become `useFooMutation`. Each composable is fully typed end to end.

Pairs with `@kubb/plugin-client` for the HTTP layer and `@kubb/plugin-ts` for types.

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

Folder where the plugin writes its generated code. The path is resolved against the global `output.path` set on `defineConfig`.

Use a folder to keep each generator's output isolated (`'types'`, `'clients'`, `'hooks'`). To put everything in one file, set `output.mode: 'file'` and point `path` at the target file including its extension (e.g. `'types.ts'`).

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'hooks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. See `output.mode` for the single-file and one-file-per-group layouts.

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
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group` — a single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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

Text prepended to every generated file. Useful for license headers, lint disables, or `@ts-nocheck` directives.

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

Text appended at the end of every generated file. The mirror of `banner` — use it for closing comments, re-enabling lint rules, or marker lines.

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
> `group` only applies to `output.mode: 'directory'` (the default), where each group becomes a folder. It is not valid with `output.mode: 'file'` — a single-file output has no grouping concept.

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
> `Required: true*` is conditional — only required when the parent `group` option is used. `group` itself stays optional.

#### group.name

Function that builds the folder/identifier name from a group key (the operation's first tag).

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### client

HTTP client used inside every generated composable. Each composable calls into this client to perform the request.

Mirrors a subset of `pluginClient` options. Set these here when the Vue composables need different client behavior than the rest of your app.

|           |                                                                                         |
| --------: | :-------------------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, bundle?, paramsCasing? }` |
| Required: | `false`                                                                                 |

#### client.importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`.

Use this when you need to inject auth headers, add interceptors, change the base URL at runtime, or wrap a different HTTP library (ky, ofetch, ...). Both relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) work.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!TIP]
> See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath) for a worked example.

> [!IMPORTANT]
> When used with query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`), generated hooks also import a `Client` type alias. Your module **must** export `Client`, `RequestConfig`, and `ResponseErrorConfig` — TypeScript will fail the import otherwise.

```typescript [src/client.ts]
import axios from 'axios'

export type RequestConfig<TData = unknown> = {
  url?: string
  method: 'GET' | 'PUT' | 'PATCH' | 'POST' | 'DELETE'
  params?: object
  data?: TData | FormData
  responseType?: 'arraybuffer' | 'blob' | 'document' | 'json' | 'text' | 'stream'
  signal?: AbortSignal
  headers?: HeadersInit
}

export type ResponseConfig<TData = unknown> = {
  data: TData
  status: number
  statusText: string
}

export type ResponseErrorConfig<TError = unknown> = TError

// Required when used with @kubb/plugin-react-query or @kubb/plugin-vue-query
export type Client = <TData, _TError = unknown, TVariables = unknown>(config: RequestConfig<TVariables>) => Promise<ResponseConfig<TData>>

const client: Client = async (config) => {
  const response = await axios.request<TData>({
    ...config,
    headers: {
      Authorization: `Bearer ${process.env.API_TOKEN}`,
      ...config.headers,
    },
  })

  return response
}

export default client
```

::: code-group

```typescript [Wire up a custom client]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      importPath: './src/client.ts',
    }),
  ],
})
```

:::

##### When to use `importPath`

Reach for a custom client when you need to:

- Add an auth token to every request.
- Plug in interceptors, retries, or logging.
- Configure `baseURL` and headers from environment variables.
- Wrap a library other than `axios`/`fetch`.

##### Default behavior

Without `importPath`:

- `bundle: false` (default) — generated code imports from `@kubb/plugin-client/clients/{axios|fetch}`.
- `bundle: true` — Kubb writes `.kubb/client.ts` and generated code imports from there.

##### Required exports

The module pointed to by `importPath` must satisfy the same shape as the built-in client. At minimum:

- A default export of the `client` function.
- A `RequestConfig` type.
- A `ResponseErrorConfig` type.

When used together with a query plugin (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`), it must also export a `Client` type alias.

##### How generated files import it

Generated code imports the client as a default import (bound to the local name `client`) and the runtime types as named type imports:

```typescript
import client from '${client.importPath}'
import type { RequestConfig, ResponseErrorConfig } from '${client.importPath}'
// ... rest of the generated file
```

#### client.dataReturnType

Shape of the value returned from each generated client function.

- `'data'` returns only the response body (`response.data`).
- `'full'` returns a discriminated union keyed by HTTP status code. Each member is `{ status: N; data: StatusNType; statusText: string }`. Narrowing on `res.status` also narrows `res.data` to the matching response type.

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

Base URL prepended to every request URL in the generated client. When omitted, the URL comes from the OpenAPI spec's `servers[0].url` (or whichever index the adapter is configured to read).

Set this when the generated client should point at a different environment (staging, production) than the one written in the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

::: code-group

```typescript [Override the spec's server URL]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      baseURL: 'https://petstore.swagger.io/v2',
    }),
  ],
})
```

:::

#### client.clientType

Style of the HTTP client that this plugin imports from `@kubb/plugin-client`.

- `'function'` — imports the function client (`getPetById(...)`). Required for query plugins.
- `'class'` — also generates a wrapper class on top, but only usable inside `@kubb/plugin-client`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'function' \| 'class'` |
| Required: | `false`                 |
|  Default: | `'function'`            |

> [!WARNING]
> Query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-svelte-query`, `@kubb/plugin-solid-query`) work only with `clientType: 'function'`. If you set `clientType: 'class'` here, the plugin falls back to generating its own inline function-based client instead of importing from `@kubb/plugin-client`.

#### client.bundle

Copies the HTTP client runtime into the generated output, so the consuming app does not need `@kubb/plugin-client` installed at runtime.

- `false` (default) — generated files import from `@kubb/plugin-client/clients/{client}`. Smaller diff, but the package must be a runtime dependency.
- `true` — Kubb writes a `.kubb/client.ts` file with the client implementation. Generated code imports from that local file and the project no longer pulls `@kubb/plugin-client` at runtime.
- Setting `client.importPath` overrides both behaviors and uses your custom client instead.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

::: code-group

```typescript [Bundle the runtime]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      client: 'fetch',
      bundle: true,
    }),
  ],
})
```

:::

### paramsType

How operation parameters (path, query, headers) are exposed in the generated function signature.

- `'inline'` (default) — each parameter is a separate positional argument. Compact for operations with one or two params.
- `'object'` — every parameter is wrapped in a single object argument. Easier to read for operations with many params and named at the call site.

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

Renames path, query, and header parameters in the generated client to the chosen casing. The HTTP request still uses the original names from the OpenAPI spec — Kubb writes the mapping for you.

- `'camelcase'` — turn `pet_id` and `X-Api-Key` into `petId` and `xApiKey` in your TypeScript code. The runtime URL still uses `/pet/{pet_id}` and the header is still sent as `X-Api-Key`.

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

How URL path parameters appear in the generated function signature. Affects only path params; query/header params follow `paramsType`.

- `'inline'` (default) — each path param is a positional argument: `getPetById(petId)`.
- `'object'` — path params are wrapped in a single object: `getPetById({ petId })`.

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

Enables `useInfiniteQuery` composables for cursor- or page-based pagination. Pass an object to configure how the cursor is read from the response; pass `false` (default) to skip.

|           |                     |
| --------: | :------------------ |
|     Type: | `Infinite \| false` |
| Required: | `false`             |
|  Default: | `false`             |

```typescript
type Infinite =
  | {
      /** Query-param key used as the page cursor. Defaults to `'id'`. */
      queryParam: string
      /** @deprecated Use `nextParam` / `previousParam` instead. */
      cursorParam?: string
      /** Path to the next-page cursor in the response. Dot or array form. */
      nextParam?: string | string[]
      /** Path to the previous-page cursor in the response. Dot or array form. */
      previousParam?: string | string[]
      /** Value of `pageParam` for the first page. Defaults to `0`. */
      initialPageParam: unknown
    }
  | false
```

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

#### infinite.cursorParam

> [!WARNING]
> **Deprecated.** `cursorParam` is deprecated. Use `nextParam` and `previousParam` for richer pagination control.

Path to the cursor field on the response. Leave undefined when the cursor is not known.

|           |                       |
| --------: | :-------------------- |
|     Type: | `string \| undefined` |
| Required: | `false`               |

#### infinite.nextParam

Path to the next-page cursor on the response. Supports dot notation (`'pagination.next.id'`) or array form (`['pagination', 'next', 'id']`).

|           |                                   |
| --------: | :-------------------------------- |
|     Type: | `string \| string[] \| undefined` |
| Required: | `false`                           |

#### infinite.previousParam

Path to the previous-page cursor on the response. Supports dot notation (`'pagination.prev.id'`) or array form.

|           |                                   |
| --------: | :-------------------------------- |
|     Type: | `string \| string[] \| undefined` |
| Required: | `false`                           |

### queryKey

Builds the `queryKey` for each generated composable. Use this to add a version namespace, swap to operation IDs, or shape keys to match an existing invalidation strategy.

The callback receives the OpenAPI `operation` and a `schemas` object containing `pathParams`, `queryParams`, `request`, and `response`.

|           |                                                                             |
| --------: | :-------------------------------------------------------------------------- |
|     Type: | `(props: { operation: Operation; schemas: OperationSchemas }) => unknown[]` |
| Required: | `false`                                                                     |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

#### Keys from tags and path parameters

Build a key from the operation's first tag plus its path parameters:

```typescript
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: ({ operation, schemas }) => {
        const tags = operation.getTags().map((tag) => JSON.stringify(tag.name))
        const pathParams = schemas.pathParams?.keys ?? []
        return [...tags, ...pathParams]
      },
    }),
  ],
})
```

```typescript
export const getUserByNameQueryKey = ({ username }: { username: GetUserByNamePathParams['username'] }) => ['user', username] as const
```

#### Extend the default transformer

Prepend a version prefix to the default query key:

```typescript
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'
import { QueryKey } from '@kubb/plugin-vue-query/components'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: (props) => {
        const defaultKeys = QueryKey.getTransformer(props)
        return [JSON.stringify('v5'), ...defaultKeys]
      },
    }),
  ],
})
```

```typescript
export const findPetsByTagsQueryKey = (params?: FindPetsByTagsQueryParams) => ['v5', { url: '/pet/findByTags' }, ...(params ? [params] : [])] as const
```

#### Key from operationId

```typescript
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: ({ operation }) => [JSON.stringify(operation.getOperationId())],
    }),
  ],
})
```

#### Conditional keys based on params

```typescript
import { defineConfig } from 'kubb'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginVueQuery({
      queryKey: ({ operation, schemas }) => {
        const keys: unknown[] = [JSON.stringify(operation.getOperationId())]

        if (schemas.pathParams?.keys) {
          keys.push(...schemas.pathParams.keys)
        }

        if (schemas.queryParams?.name) {
          keys.push('...(params ? [params] : [])')
        }

        return keys
      },
    }),
  ],
})
```

### query

Configures the query composables. Pass `false` to skip composable generation and emit only `queryOptions(...)` helpers.

|           |         |
| --------: | :------ |
|     Type: | `Query` |
| Required: | `false` |

```typescript
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

Module specifier used in the `import { useQuery } from '...'` statement at the top of every generated composable file. Useful for routing through your own wrapper.

|           |                         |
| --------: | :---------------------- |
|     Type: | `string`                |
| Required: | `false`                 |
|  Default: | `'@tanstack/vue-query'` |

### mutation

Configures mutation composables. Set to `false` to skip mutation generation.

|           |            |
| --------: | :--------- |
|     Type: | `Mutation` |
| Required: | `false`    |

```typescript
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

Module specifier used in the `import { useMutation } from '...'` statement at the top of every generated composable file.

|           |                         |
| --------: | :---------------------- |
|     Type: | `string`                |
| Required: | `false`                 |
|  Default: | `'@tanstack/vue-query'` |

### mutationKey

Builds the `mutationKey` for each mutation composable. Useful when you batch invalidations or read mutation state via `useMutationState`.

|           |                                                                             |
| --------: | :-------------------------------------------------------------------------- |
|     Type: | `(props: { operation: Operation; schemas: OperationSchemas }) => unknown[]` |
| Required: | `false`                                                                     |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### include

Restricts generation to operations that match at least one entry in the list. Anything not matched is skipped.

Each entry filters by one of:

- `tag` — the operation's first tag in the OpenAPI spec.
- `operationId` — the operation's `operationId`.
- `path` — the URL pattern (`'/pet/{petId}'`).
- `method` — HTTP method (`'get'`, `'post'`, ...).
- `contentType` — the media type of the request body.

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

- `tag` — the operation's first tag.
- `operationId` — the operation's `operationId`.
- `path` — the URL pattern (`'/pet/{petId}'`).
- `method` — HTTP method (`'get'`, `'post'`, ...).
- `contentType` — the media type of the request body.

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

Entries are evaluated top to bottom. The first matching entry's `options` is merged onto the plugin defaults; later entries do not stack.

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

|           |                                    |
| --------: | :--------------------------------- |
|     Type: | `Array<Generator<PluginVueQuery>>` |
| Required: | `false`                            |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### resolver

Overrides naming and path resolution for the generated composables. Supply only the methods you want to change; everything else falls back to the default resolver.

|           |                             |
| --------: | :-------------------------- |
|     Type: | `Partial<ResolverVueQuery>` |
| Required: | `false`                     |

### transformer

AST visitor applied to operation nodes before code is printed. Use this to rewrite operation IDs, tags, or descriptions across the entire output.

|           |               |
| --------: | :------------ |
|     Type: | `ast.Visitor` |
| Required: | `false`       |

## Dependencies

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-client`](/plugins/plugin-client)

## Example

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
