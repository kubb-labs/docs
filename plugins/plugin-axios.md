---
layout: doc
title: Kubb Axios Plugin
description: Generate a type-safe axios HTTP client from OpenAPI, one async
  function per operation, fully typed end to end.
outline: 2
kind: plugin
id: plugin-axios
name: Axios
category: client
type: official
npmPackage: "@kubb/plugin-axios"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-axios
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
  - http-client
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-axios
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/axios
---

# @kubb/plugin-axios

`@kubb/plugin-axios` turns each OpenAPI operation into a typed async function that calls your API with [axios](https://axios-http.com/). The path, query parameters, request body, response, and error shape all come from the spec, so a call stays in sync with the API it targets.

It builds on `@kubb/plugin-ts` for the types, so add that to your config. Axios is a runtime dependency, so install it next to your application code.

Each generated function takes one grouped options object (`{ path, query, headers, body }`) and returns a `RequestResult` of `{ data, error, request, response }`. `throwOnError` defaults to `true`, so a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` per call to get the discriminated `{ data?, error? }` form and read `error` and `response.status` yourself. The runtime is always bundled into `.kubb/client.ts`, so there is no `bundle` option.

The bundled `client` also exposes a `getUrl` method. It returns the final URL for an operation from the base URL, the interpolated path params, and the serialized query, without sending the request. This helps when you build cache keys, prefetch data, or render links:

```ts
import { client } from './.kubb/client'

const url = client.getUrl({ url: '/pet/{petId}', path: { petId: 1 }, query: { status: ['available'] } })
// '/pet/1?status=available'
```

To authenticate requests, give the client one `auth` resolver and the runtime adds the credential to every call its security schemes guard. The [authentication guide](/docs/5.x/guides/authentication) walks through bearer, basic, and apiKey setups.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-axios@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-axios@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-axios@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-axios@beta
```

:::

## Options

### output

Where the plugin writes the generated functions and how it exports them.

|           |                                                  |
| --------: | :----------------------------------------------- |
|     Type: | `Output`                                         |
| Required: | `false`                                          |
|  Default: | `{ path: 'clients', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files, resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

|           |             |
| --------: | :---------- |
|     Type: | `string`    |
| Required: | `true`      |
|  Default: | `'clients'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files. `'directory'` (the default) writes one file per operation under `output.path`. `'file'` writes everything into a single file, so `output.path` must include the file extension, such as `'clients.ts'`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

How the generated `index.ts` barrel file re-exports the plugin's output. `{ type: 'named' }` re-exports each symbol by name, which is best for tree-shaking and explicit imports. `{ type: 'all' }` uses `export *` for a smaller barrel that exports everything. Add `nested: true` to create a barrel in every subdirectory, so callers can import from any depth. Set `false` to skip the barrel entirely, which also excludes the plugin's files from the root `index.ts`.

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

Splits generated files into subfolders by the operation's first tag or first path segment. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |
|  Default: | `null`  |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get a barrel file per group.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

#### group.type

Property used to assign each operation to a group, required whenever `group` is set. `'tag'` reads the first tag on the operation (`operation.getTags().at(0)?.name`), and operations without a tag go in a default group. `'path'` reads the first segment of the operation's URL.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required` here is conditional. It applies only when the parent `group` option is set, and `group` itself stays optional.

#### group.name

Function that builds the folder name from the group key. The default depends on `group.type`. A `'tag'` group uses the camelCased tag. A `'path'` group uses the second path segment (`/pet/findByStatus` becomes `pet`). A `group.name` you pass always wins over the default.

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                   |

### exclude

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use a `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and a `pattern` (string or `RegExp`). When both are set, `exclude` wins.

|           |                  |
| --------: | :--------------- |
|     Type: | `Array<Exclude>` |
| Required: | `false`          |
|  Default: | `[]`             |

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

### include

Generates only the operations that match at least one entry in the list, and skips everything else. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`) as `exclude`.

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

### override

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

|           |                   |
| --------: | :---------------- |
|     Type: | `Array<Override>` |
| Required: | `false`           |
|  Default: | `[]`              |

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Partial<Options>
}
```

### baseURL

Base URL prepended to every request the functions make. When omitted, the URL comes from the adapter's server URL (`servers[0].url` in the spec). Set it to point the client at a different environment, such as staging or production, than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### parser

Runtime validator applied to request and response bodies using schemas from `@kubb/plugin-zod`. `false` (the default) does no validation and returns the response cast to the generated type. `'zod'` validates success response bodies only. The `{ request?: 'zod', response?: 'zod' }` object form opts in per direction, where `request` validates the request body before the call and `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`.

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

The value changes what the generated function does with the response:

::: code-group

```typescript [false]
export function getPetById<ThrowOnError extends boolean = true>(
  options: Options<GetPetByIdRequestConfig, ThrowOnError>,
): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'GET',
    url: '/pet/{petId}',
    ...config,
  }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
}
```

```typescript ['zod']
export function getPetById<ThrowOnError extends boolean = true>(
  options: Options<GetPetByIdRequestConfig, ThrowOnError>,
): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  const result = await request({
    method: 'GET',
    url: '/pet/{petId}',
    ...config,
  })

  result.data = getPetByIdQueryResponseSchema.parse(result.data)
  return result as RequestResult<GetPetByIdResponses, ThrowOnError>
}
```

```typescript [{ request, response }]
export function addPet<ThrowOnError extends boolean = true>(
  options: Options<AddPetRequestConfig, ThrowOnError>,
): Promise<RequestResult<AddPetResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  config.data = addPetMutationRequestSchema.parse(config.data)

  const result = await request({
    method: 'POST',
    url: '/pet',
    ...config,
  })

  result.data = addPetMutationResponseSchema.parse(result.data)
  return result as RequestResult<AddPetResponses, ThrowOnError>
}
```

:::

### sdk

Generates a class-based SDK instead of standalone functions. Each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. Leave `sdk` unset to keep the per-operation functions, which is what the query plugins consume.

|           |                                             |
| --------: | :------------------------------------------ |
|     Type: | `{ mode?: 'tag' \| 'flat'; name?: string }` |
| Required: | `false`                                     |

The `sdk.mode` value changes the shape the plugin emits:

::: code-group

```typescript ['tag']
export class PetClient {
  private readonly client: ClientInstance

  constructor(config: ClientConfig = {}) {
    this.client = createClient(config)
  }

  public getPetById<ThrowOnError extends boolean = true>(
    options: Options<GetPetByIdRequestConfig, ThrowOnError>,
  ): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
    const { client: request = this.client, ...config } = options

    return request({ method: 'GET', url: '/pet/{petId}', ...config }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
  }
}
```

```typescript ['flat']
export class PetStore {
  private readonly client: ClientInstance

  constructor(config: ClientConfig = {}) {
    this.client = createClient(config)
  }

  public getPetById<ThrowOnError extends boolean = true>(
    options: Options<GetPetByIdRequestConfig, ThrowOnError>,
  ): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
    const { client: request = this.client, ...config } = options

    return request({ method: 'GET', url: '/pet/{petId}', ...config }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
  }

  public placeOrder<ThrowOnError extends boolean = true>(
    options: Options<PlaceOrderRequestConfig, ThrowOnError>,
  ): Promise<RequestResult<PlaceOrderResponses, ThrowOnError>> {
    const { client: request = this.client, ...config } = options

    return request({ method: 'POST', url: '/store/order', ...config }) as Promise<RequestResult<PlaceOrderResponses, ThrowOnError>>
  }
}
```

:::

`mode: 'tag'` (the default) emits one class per tag, such as `PetClient` and `StoreClient`. Set `sdk.name` alongside it to also emit a composed root class that instantiates every tag client from one shared config, reached as `new PetStore(config).pet.getPetById(...)`. `mode: 'flat'` emits a single class named by `sdk.name` with every operation as a direct method. Omitting `sdk` keeps the standalone per-operation functions.

Using the generated SDK works the same across modes. Construct the class once with a client config (`baseURL`, `headers`, and the other `ClientConfig` fields), then call a method with the grouped options object (`{ path, query, headers, body }`) and read `data` off the result:

::: code-group

```typescript ['tag']
import { PetClient } from './src/gen/clients/petClient'
import { StoreClient } from './src/gen/clients/storeClient'

const config = { baseURL: 'https://petstore.swagger.io/v2' }
const pet = new PetClient(config)
const store = new StoreClient(config)

const { data: foundPet } = await pet.getPetById({ path: { petId: 1 } })
await store.placeOrder({ body: { petId: 1, quantity: 1 } })
```

```typescript ['tag' + sdk.name]
import { PetStore } from './src/gen/clients/petStore'

const api = new PetStore({ baseURL: 'https://petstore.swagger.io/v2' })

const { data: foundPet } = await api.pet.getPetById({ path: { petId: 1 } })
await api.store.placeOrder({ body: { petId: 1, quantity: 1 } })
```

```typescript ['flat']
import { PetStore } from './src/gen/clients/petStore'

const api = new PetStore({ baseURL: 'https://petstore.swagger.io/v2' })

const { data: foundPet } = await api.getPetById({ path: { petId: 1 } })
await api.placeOrder({ body: { petId: 1, quantity: 1 } })
```

:::

Each call resolves to `{ data, error, request, response }`. Because `throwOnError` defaults to `true`, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` on a call to get the discriminated `{ data?, error? }` form and read `error` and `response.status` yourself:

```typescript
const { data, error, response } = await pet.getPetById({ path: { petId: 1 }, throwOnError: false })

if (error) {
  console.error(response.status, error)
} else {
  console.log(data)
}
```

### resolver

Changes how the plugin names generated files and functions. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `Partial<ResolverClient> & ThisType<ResolverClient>` |
| Required: | `false`                                              |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.

### macros

Rewrites AST nodes before the plugin prints them to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback, such as `schema` or `operation`, receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

## Dependencies

This plugin needs `@kubb/plugin-ts` in your config. Kubb runs it before `plugin-axios` so the functions can import the generated types. When `parser` is set to `'zod'`, also add `@kubb/plugin-zod`.

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-zod`](/plugins/plugin-zod)

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios({
      output: { path: 'clients', barrel: { type: 'named' } },
      baseURL: 'https://petstore.swagger.io/v2',
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Service`,
      },
    }),
  ],
})
```

:::

## See also

- [axios](https://axios-http.com/)
- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md)
