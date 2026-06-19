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

`@kubb/plugin-client` generates one HTTP client function per operation in your OpenAPI spec. Each function types its path params, query params, body, and response. You call the API like any other typed function.

Every generated function takes a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

The plugin ships with `axios` and `fetch` runtimes. To bring your own client for auth, retries, or a custom base URL, point `importPath` at your module.

**See also**

- [axios](https://axios-http.com/)
- [`@kubb/plugin-ts`](/plugins/plugin-ts)

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

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

|           |             |
| --------: | :---------- |
|     Type: | `string`    |
| Required: | `true`      |
|  Default: | `'clients'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

`'directory'` (the default) writes one file per operation under `output.path`. `'file'` writes everything into a single file, in which case `output.path` must include the file extension (for example `'clients.ts'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

Controls how the generated `index.ts` (barrel) file re-exports the plugin's output.

`{ type: 'named' }` re-exports each symbol by name. It tree-shakes well and keeps imports explicit. `{ type: 'all' }` uses `export *` for a smaller barrel that exports everything. Add `{ nested: true }` to create a barrel in every subdirectory. Set it to `false` to skip the barrel and leave the plugin's files out of the root `index.ts`.

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

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient({
      group: { type: 'tag' },
    }),
  ],
})
```

```text [Resulting tree]
src/gen/clients/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    └── getInventory.ts
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

Function that turns a group key (the operation's first tag) into a folder name. For example, a `name` function that appends `Controller` keeps the pre-v5 `petController/` layout.

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### client

HTTP client used by the generated code. To plug in your own client, use [`importPath`](#importpath) instead.

`'axios'` calls into `@kubb/plugin-client/clients/axios` and needs `axios` as a runtime dependency. `'fetch'` calls into `@kubb/plugin-client/clients/fetch` and uses the global `fetch` with no extra dependency.

|           |                      |
| --------: | :------------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`              |
|  Default: | `'axios'`            |

::: code-group

```typescript [axios (default)]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      client: 'axios',
    }),
  ],
})
```

```typescript [fetch]
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

### importPath

Path or module specifier of a custom client module. By default the selected `client` is bundled into `.kubb/client.ts` and the generated code imports it from there. Set `importPath` to skip that bundle and import the runtime straight from your own module. Use it to inject auth headers, attach interceptors, or wrap a library such as ky or ofetch. Relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) both work. `importPath` takes priority over `client`.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!IMPORTANT]
> The module must default-export the `client` function and export a `RequestConfig` type and a `ResponseErrorConfig` type. With a query plugin (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`), it must also export a `Client` type alias, or TypeScript fails the import.

Generated code imports the client as a default import (named `client`) and the runtime types as named type imports.

```typescript [src/client.ts]
import axios from 'axios'

export type RequestConfig<TData = unknown> = {
  url?: string
  method: 'GET' | 'PUT' | 'PATCH' | 'POST' | 'DELETE'
  query?: object
  body?: TData | FormData
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

// Required with @kubb/plugin-react-query or @kubb/plugin-vue-query
export type Client = <TData, _TError = unknown, TVariables = unknown>(config: RequestConfig<TVariables>) => Promise<ResponseConfig<TData>>

const client: Client = async ({ query, body, ...config }) => {
  const response = await axios.request<TData>({
    ...config,
    params: query,
    data: body,
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

### clientType

Shape of the generated client code.

`'function'` (the default) emits one standalone async function per operation. It tree-shakes cleanly and works with every query plugin. `'class'` emits one class per tag with an instance method per operation, so you can share config such as auth and headers through the constructor. `'staticClass'` emits one class per tag with static methods, called as `Pet.getPetById(...)` without instantiating.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `'function' \| 'class' \| 'staticClass'` |
| Required: | `false`                                  |
|  Default: | `'function'`                             |

> [!WARNING]
> Only `'function'` works with query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`). To use both classes and query hooks, register two `pluginClient` instances. One uses `clientType: 'function'` for the query plugins, the other uses `'class'` or `'staticClass'` for your direct usage.

::: code-group

```typescript ['function' (default)]
export async function getPetById({ path }: Omit<GetPetByIdRequestConfig, 'url'>, config: Partial<RequestConfig> = {}) {
  const res = await client<GetPetByIdQueryResponse>({
    method: 'GET',
    url: `/pet/${path.petId}`,
    ...config,
  })
  return res.data
}
```

```typescript ['class']
export class PetClient {
  #config: Partial<RequestConfig> & { client?: Client }

  constructor(config: Partial<RequestConfig> & { client?: Client } = {}) {
    this.#config = config
  }

  async getPetById({ path }: Omit<GetPetByIdRequestConfig, 'url'>, config: Partial<RequestConfig> = {}) {
    const { client: request = client, ...requestConfig } = mergeConfig(this.#config, config)
    const res = await request<GetPetByIdQueryResponse>({ method: 'GET', url: `/pet/${path.petId}`, ...requestConfig })
    return res.data
  }
}
```

```typescript ['staticClass']
export class PetClient {
  static #config: Partial<RequestConfig> & { client?: Client } = {}

  static async getPetById({ path }: Omit<GetPetByIdRequestConfig, 'url'>, config: Partial<RequestConfig> = {}) {
    const { client: request = client, ...requestConfig } = mergeConfig(this.#config, config)
    const res = await request<GetPetByIdQueryResponse>({ method: 'GET', url: `/pet/${path.petId}`, ...requestConfig })
    return res.data
  }
}
```

:::

### sdk

Generates a single SDK class that composes the per-tag client classes into one entry point. You pass one object around your app (`api.pet.findById`, `api.user.login`) instead of importing each tag client. Setting `sdk` enables `clientType: 'class'` for you, so you only add `group: { type: 'tag' }` to split the clients per tag.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ className: string }` |
| Required: | `false`                 |

#### sdk.className

Name of the generated SDK class. Used as the export name and the file name.

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

```typescript [usage.ts]
import { PetStoreClient } from './gen/clients/PetStoreClient'

const api = new PetStoreClient({ baseURL: 'https://petstore.swagger.io/v2' })

const pets = await api.pet.findPetsByTags({ query: { tags: ['available'] } })
const user = await api.user.getUserByName({ path: { username: 'john' } })
```

:::

### dataReturnType

Shape of the value returned from each generated client function.

`'data'` (the default) returns only the response body (`response.data`). `'full'` returns a discriminated union keyed by HTTP status code. Each member is `{ status: N; data: StatusNType; statusText: string }`, so narrowing on `res.status` also narrows `res.data` to the matching response type.

|           |                    |
| --------: | :----------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`            |
|  Default: | `'data'`           |

::: code-group

```typescript ['data' (default)]
const pet = await getPetById({ path: { petId: 1 } })
//    ^? Pet
```

```typescript ['full']
const res = await getPetById({ path: { petId: 1 } })
if (res.status === 200) {
  res.data // narrowed to the 200 response type
}
```

:::

### parser

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`. Requires `@kubb/plugin-zod` in the plugins list when either direction is set to `'zod'`.

`false` (the default) does no validation and returns the response cast to the generated type. `'zod'` validates response bodies only. `{ request?: 'zod', response?: 'zod' }` opts in per direction, where `request` validates the request body and query params before the call and `response` validates the response body after.

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

::: code-group

```typescript [Validate responses]
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

```typescript [Validate request and response]
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

### urlType

Controls whether the URL builder helpers (`get<Operation>Url`) are exported alongside each client function.

`'export'` exposes them through the barrel, so you can call the API through a different transport such as `navigator.sendBeacon` or a server action. `false` (the default) keeps them private to the generated module.

|           |                     |
| --------: | :------------------ |
|     Type: | `'export' \| false` |
| Required: | `false`             |
|  Default: | `false`             |

The helper takes the operation's `path` group, typed from its `RequestConfig`, and reads each path param off it.

```typescript [Generated URL helper]
export function getGetPetByIdUrl(path: GetPetByIdRequestConfig['path']) {
  const res = { method: 'GET', url: `/pet/${path.petId}` as const }

  return res
}
```

### baseURL

Base URL prepended to every request URL in the generated client. Use it to point at a different environment (staging, production) than the spec. When omitted, the URL comes from the spec's `servers[0].url` (or whichever index the adapter reads).

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

### operations

Emits an `operations.ts` file that re-exports every generated function grouped by HTTP method. Use it to build meta-tooling such as route registries or API explorers on top of the generated code.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of `tag` (the operation's first tag), `operationId`, `path` (the URL path, such as `'/pet/{petId}'`), `method` (such as `'get'` or `'post'`), or `contentType` (the request body media type). `pattern` accepts a string (exact match) or a `RegExp` for fuzzy matches.

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
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
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
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
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

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object that accepts any plugin-client option such as `client` or `dataReturnType`. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

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

```typescript [Return the full response only for the user tag]
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
          options: { dataReturnType: 'full' },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name)` to reuse the built-in name.

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

### generators

Adds custom generators that run next to the built-in ones. Each generator can emit extra files or post-process existing ones using the plugin's AST and options. Use it for output the plugin does not produce, such as a custom client wrapper or a metadata file. See [Creating plugins](/docs/5.x/guides/creating-plugins).

|           |                                  |
| --------: | :------------------------------- |
|     Type: | `Array<Generator<PluginClient>>` |
| Required: | `false`                          |

> [!WARNING]
> Generators are an experimental, low-level API. The signature may change between minor releases.

### macros

Rewrites operation nodes before they are printed to source. Use it to rename operation IDs, tags, or descriptions across the whole client. Each [macro](/docs/5.x/concepts/macros) callback receives the node and a context object. Return a new node to replace it, or `null`/`undefined` to leave it as is.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

```typescript twoslash [Prefix every operationId with "api_"]
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

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-client/CHANGELOG.md)
