---
layout: doc
title: Kubb Client Plugin
description: Generate type-safe HTTP clients (axios or fetch) from OpenAPI, one
  async function per operation, fully typed end to end.
outline: 2
kind: plugin
id: plugin-client
name: Client
category: client
type: official
npmPackage: "@kubb/plugin-client"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-client
featured: true
icon:
  light: https://kubb.dev/feature/axios.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - api-client
  - axios
  - fetch
  - http-client
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-client
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-client/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/client
---

# @kubb/plugin-client

Generate HTTP client functions for every operation in your OpenAPI spec. Each function types its path params, query params, body, and response, so you call the API like any other typed function.

The plugin ships with `axios` and `fetch` runtimes. To bring your own client for auth, retries, or a custom base URL, point `importPath` at your module.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-client@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-client@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-client@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-client@beta
```

:::

## Options

### output

Where the generated client files are written and how they are exported.

|           |                                                  |
| --------: | :----------------------------------------------- |
|     Type: | `Output`                                         |
| Required: | `false`                                          |
|  Default: | `{ path: 'clients', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its generated code, resolved against the global `output.path` set on `defineConfig`. To put everything in one file instead, set `output.mode: 'file'` and point `path` at a target file including its extension (for example `'types.ts'`).

|           |             |
| --------: | :---------- |
|     Type: | `string`    |
| Required: | `true`      |
|  Default: | `'clients'` |

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

Pass `group.name` to customize the folder name. For example, `name: ({ group }) => \`${group}Controller\`` keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

Today only `'tag'` is supported. Kubb reads the first tag on the operation (`operation.getTags().at(0)?.name`) and uses it as the group key. Operations without a tag go into a default group.

|           |         |
| --------: | :------ |
|     Type: | `'tag'` |
| Required: | `true`  |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder/identifier name from a group key (the operation's first tag).

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`. Use this to inject auth headers, attach interceptors, or wrap a different HTTP library such as ky or ofetch. Both relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) work. Setting `importPath` takes priority over `client` and turns off `bundle`, since the runtime now comes from your module.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!TIP]
> See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath) for a worked example.

> [!IMPORTANT]
> When used with query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`), generated hooks also import a `Client` type alias. Your module must export `Client`, `RequestConfig`, and `ResponseErrorConfig`, or TypeScript will fail the import.

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

#### Default behavior

Without `importPath`:

- `bundle: false` (default): generated code imports from `@kubb/plugin-client/clients/{axios|fetch}`.
- `bundle: true`: Kubb writes `.kubb/client.ts` and generated code imports from there.

#### Required exports

The module must match the shape of the built-in client: a default export of the `client` function, a `RequestConfig` type, and a `ResponseErrorConfig` type. With a query plugin (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`) it must also export a `Client` type alias.

#### How generated files import it

Generated code imports the client as a default import (bound to the local name `client`) and the runtime types as named type imports:

```typescript
import client from '${client.importPath}'
import type { RequestConfig, ResponseErrorConfig } from '${client.importPath}'
// ... rest of the generated file
```

### operations

Emits an `operations.ts` file that re-exports every generated function grouped by HTTP method, useful for building meta-tooling such as route registries or API explorers on top of the generated code.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### dataReturnType

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

### urlType

Controls whether the URL builder helpers (`get<Operation>Url`) are exported alongside each client function.

- `'export'`: expose them through the barrel, for calling the API through a different transport such as `navigator.sendBeacon` or server actions.
- `false` (default): keep them private to the generated module.

|           |                     |
| --------: | :------------------ |
|     Type: | `'export' \| false` |
| Required: | `false`             |
|  Default: | `false`             |

```typescript [Generated URL helper]
export function getGetPetByIdUrl(petId: GetPetByIdPathParams['petId']) {
  return `/pet/${petId}` as const
}
```

### paramsType

How operation parameters (path, query, headers) are exposed in the generated function signature.

- `'inline'` (default): each parameter is a separate positional argument. Compact for operations with one or two params.
- `'object'`: every parameter is wrapped in a single object argument. Easier to read for operations with many params, and named at the call site.

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

Renames path, query, and header parameters in the generated client to the chosen casing. The HTTP request still uses the original names from the OpenAPI spec, and Kubb writes the mapping for you.

- `'camelcase'`: turn `pet_id` and `X-Api-Key` into `petId` and `xApiKey` in your TypeScript code. The runtime URL still uses `/pet/{pet_id}` and the header is still sent as `X-Api-Key`.

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

- `'inline'` (default): each path param is a positional argument, as in `getPetById(petId)`.
- `'object'`: path params are wrapped in a single object, as in `getPetById({ petId })`.

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

With `coercion` enabled in `@kubb/plugin-zod`, request-side parsing also normalizes types. For example, `z.coerce.number()` converts a stringified number from a form field.

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

### client

HTTP client used by the generated code.

- `'axios'`: generated functions call into `@kubb/plugin-client/clients/axios`. Requires `axios` as a runtime dependency.
- `'fetch'`: generated functions call into `@kubb/plugin-client/clients/fetch`. Uses the global `fetch` with no extra runtime dependency.

To plug in your own client, use [`importPath`](#importpath) instead.

|           |                      |
| --------: | :------------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`              |
|  Default: | `'axios'`            |

::: code-group

```typescript [Use fetch]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      client: 'fetch',
    }),
  ],
})
```

:::

### clientType

Shape of the generated client code.

- `'function'` (default): one standalone async function per operation. Tree-shakes cleanly and works with every query plugin.
- `'class'`: one class per group/tag with an instance method per operation. Use this to share configuration such as auth and headers through the constructor.
- `'staticClass'`: one class per group/tag with static methods. Call as `Pet.getPetById(...)` without instantiating. Good for app-wide singleton clients.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `'function' \| 'class' \| 'staticClass'` |
| Required: | `false`                                  |
|  Default: | `'function'`                             |

> [!WARNING]
> Only `'function'` is compatible with query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`). To use both classes and query hooks, register two `pluginClient` instances. The first uses `clientType: 'function'` for the query plugins to consume, and the second uses `clientType: 'class'` or `'staticClass'` for your direct usage.

::: code-group

```typescript ['staticClass']
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      output: { path: './clients' },
      clientType: 'staticClass',
      group: { type: 'tag' },
    }),
  ],
})
```

```typescript [Generated petClient.ts (excerpt)]
import type { Client, RequestConfig } from './.kubb/client'
import type { GetPetByIdPathParams, GetPetByIdQueryResponse } from '../../models/ts/pet/GetPetById'
import { client, mergeConfig } from './.kubb/client'

export class PetClient {
  static #config: Partial<RequestConfig> & { client?: Client } = {}

  static async getPetById({ petId }: { petId: GetPetByIdPathParams['petId'] }, config: Partial<RequestConfig> & { client?: Client } = {}) {
    const { client: request = client, ...requestConfig } = mergeConfig(this.#config, config)
    const res = await request<GetPetByIdQueryResponse>({
      method: 'GET',
      url: `/pet/${petId}`,
      ...requestConfig,
    })
    return res.data
  }
}
```

```typescript [usage.ts]
import { PetClient } from './gen/clients/petClient'

const pet = await PetClient.getPetById({ petId: 1 })
```

```typescript ['class']
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      output: { path: './clients' },
      clientType: 'class',
      group: { type: 'tag' },
    }),
  ],
})
```

```typescript [Generated petClient.ts (excerpt)]
import type { Client, RequestConfig } from './.kubb/client'
import type { GetPetByIdPathParams, GetPetByIdQueryResponse } from '../../models/ts/pet/GetPetById'
import { client, mergeConfig } from './.kubb/client'

export class PetClient {
  #config: Partial<RequestConfig> & { client?: Client }

  constructor(config: Partial<RequestConfig> & { client?: Client } = {}) {
    this.#config = config
  }

  async getPetById({ petId }: { petId: GetPetByIdPathParams['petId'] }, config: Partial<RequestConfig> & { client?: Client } = {}) {
    const { client: request = client, ...requestConfig } = mergeConfig(this.#config, config)
    const res = await request<GetPetByIdQueryResponse>({
      method: 'GET',
      url: `/pet/${petId}`,
      ...requestConfig,
    })
    return res.data
  }
}
```

```typescript [usage.ts]
import { PetClient } from './gen/clients/petClient'

const petClient = new PetClient()
const pet = await petClient.getPetById({ petId: 1 })
```

:::

### sdk

Generates a single SDK class that composes the per-tag client classes into one entry point, so you can pass one object around your app (`api.pet.findById`, `api.user.login`) instead of importing each tag client separately. Setting `sdk` automatically enables `clientType: 'class'`, so you only add `group: { type: 'tag' }` to split the clients per tag.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ className: string }` |
| Required: | `false`                 |

#### sdk.className

Name of the generated SDK class, used as the export name and file name.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `true`   |

::: code-group

```typescript [A composed PetStoreClient]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      output: { path: './clients' },
      group: { type: 'tag' },
      sdk: { className: 'PetStoreClient' },
    }),
  ],
})
```

```typescript [Generated PetStoreClient.ts]
import type { Client, RequestConfig } from './.kubb/client'
import { PetClient } from './pet/PetClient'
import { StoreClient } from './store/StoreClient'
import { UserClient } from './user/UserClient'

export class PetStoreClient {
  readonly pet: PetClient
  readonly store: StoreClient
  readonly user: UserClient

  constructor(config: Partial<RequestConfig> & { client?: Client } = {}) {
    this.pet = new PetClient(config)
    this.store = new StoreClient(config)
    this.user = new UserClient(config)
  }
}
```

```typescript [usage.ts]
import { PetStoreClient } from './gen/clients/PetStoreClient'

const api = new PetStoreClient({ baseURL: 'https://petstore.swagger.io/v2' })

const pets = await api.pet.findPetsByTags({ tags: ['available'] })
const user = await api.user.getUserByName({ username: 'john' })
```

:::

### bundle

Copies the HTTP client runtime into the generated output, so the consuming app does not need `@kubb/plugin-client` installed at runtime.

- `false` (default): generated files import from `@kubb/plugin-client/clients/{client}`. Smaller diff, but the package must be a runtime dependency.
- `true`: Kubb writes a `.kubb/client.ts` with the client implementation and generated code imports from there, so the project no longer pulls `@kubb/plugin-client` at runtime.
- Setting `importPath` overrides both behaviors and uses your custom client instead, so `bundle` has no effect.

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

### baseURL

Base URL prepended to every request URL in the generated client, for pointing at a different environment (staging, production) than the spec. When omitted, the URL comes from the spec's `servers[0].url` (or whichever index the adapter is configured to read).

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

### include

Restricts generation to operations that match at least one entry in the list. Anything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL pattern, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
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

Applies a different set of plugin options to operations that match a pattern, for the few endpoints that need their own settings. Each entry takes the same `type` and `pattern` as `include`/`exclude`, plus an `options` object (any plugin-client option, such as `bundle`, `client`, or `dataReturnType`). Entries evaluate top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

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

```typescript [Bundle the runtime only for the user tag]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      client: 'fetch',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { bundle: true },
        },
      ],
    }),
  ],
})
```

:::

### generators

Adds custom generators that run alongside the built-in ones, each emitting extra files or post-processing existing ones using the plugin's AST and options. Use it for output the plugin does not produce out of the box, such as a custom client wrapper, an extra index, or a metadata file. See [Creating plugins](https://kubb.dev/docs/5.x/guides/creating-plugins).

|           |                                  |
| --------: | :------------------------------- |
|     Type: | `Array<Generator<PluginClient>>` |
| Required: | `false`                          |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### resolver

Overrides naming and path resolution for the generated client. Only the methods you supply replace the defaults. Everything else falls back to the built-in resolver. Inside each method, `this` is bound to the full resolver, so you can call `this.default(name)` to delegate to the original implementation.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `Partial<ResolverClient> & ThisType<ResolverClient>` |
| Required: | `false`                                              |

```typescript [Append "Client" to every name]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      resolver: {
        resolveName(name) {
          return `${this.default(name)}Client`
        },
      },
    }),
  ],
})
```

### macros

A list of [macros](/docs/5.x/concepts/macros) applied to operation nodes before code is printed, for rewriting operation IDs, tags, or descriptions across the entire client.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

```typescript [Prefix every operationId with "api_"]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
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

## Dependencies

This plugin requires the following plugins to be installed:

- [`@kubb/plugin-ts`](/plugins/plugin-ts)

## Example

::: code-group

<<< @/snippets/plugins/plugin-client/kubb.config.ts [kubb.config.ts]

:::
