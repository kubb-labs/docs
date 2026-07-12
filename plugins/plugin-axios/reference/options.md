---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-axios.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'clients', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` | `false` | Validate request and response bodies with Zod |
| [`sdk`](#sdk) | `{ mode?: 'tag' \| 'flat'; name?: string }` | — | Emit a class-based SDK instead of standalone functions |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverClient>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'clients', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'clients.ts'`.

|          |             |
| -------: | :---------- |
|    Type: | `string`    |
| Default: | `'clients'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'clients.ts'`).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'directory' \| 'file'` |
| Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

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
// src/gen/clients/index.ts
export { getPetById } from './getPetById'
export { addPet } from './addPet'
```

```typescript ['all']
// src/gen/clients/index.ts
export * from './getPetById'
export * from './addPet'
```

```text [nested]
src/gen/clients/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPetById, addPet, ...
│   └── getPetById.ts
└── store/
    ├── index.ts
    └── placeOrder.ts
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

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file. A function banner builds the text from the meta, such as `banner: (meta) => \`// Source: ${meta.filePath}\``.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the same `BannerMeta` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|          |         |
| -------: | :------ |
|    Type: | `Group` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag.

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Service` to the group keeps a `petService/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key into a folder name. The default depends on `group.type`. A `'tag'` group uses the camelCased tag. A `'path'` group uses the first path segment (`/pet/findByStatus` becomes `pet`). A `group.name` you pass always wins over the default.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: { group: string }) => string` |

### baseURL

Base URL prepended to every request the functions make. When omitted, the client falls back to the server URL the [OpenAPI adapter](/adapters/adapter-oas/) resolves, which it only does when the adapter's `server.index` points at an entry in the spec's `servers` list. Set it to point the client at a different environment, such as staging or production, than the spec.

A value containing a `${...}` interpolation is emitted as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable when the app runs instead of baking in the build-time value.

|          |          |
| -------: | :------- |
|    Type: | `string` |

### validator

Runtime validator applied to request and response bodies using schemas from `@kubb/plugin-zod`.

- `false` (default) does no validation and returns the response cast to the generated type.
- `'zod'` validates the success response body, and the error body when a non-2xx call does not throw.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction, where `request` validates the request body before the call and `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`.

|          |                                                           |
| -------: | :-------------------------------------------------------- |
|    Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Default: | `false`                                                   |

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

  return request({
    method: 'GET',
    url: '/pet/{petId}',
    validator: { response: getPetByIdResponseSchema },
    ...config,
  }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
}
```

```typescript [{ request, response }]
export function addPet<ThrowOnError extends boolean = true>(
  options: Options<AddPetRequestConfig, ThrowOnError>,
): Promise<RequestResult<AddPetResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'POST',
    url: '/pet',
    validator: { request: addPetBodySchema, response: addPetResponseSchema, error: addPetErrorSchema },
    ...config,
  }) as Promise<RequestResult<AddPetResponses, ThrowOnError>>
}
```

:::

You call the generated function the same way for every value. With `'zod'` the response is validated and a `ParseError` throws on invalid data, and the `{ request }` form validates the request body before the call:

```typescript
import { addPet } from './src/gen/clients/addPet'

// throws a ParseError when the request body or response fails its schema
const { data } = await addPet({ body: { name: 'Fluffy' } })
```

### sdk

Generates a class-based SDK instead of standalone functions. Each tag client is an instance class whose constructor takes a client config and builds its own client, so every environment is a separate instance. Leave `sdk` unset to keep the per-operation functions, which is what the query plugins consume.

|          |                                             |
| -------: | :------------------------------------------ |
|    Type: | `{ mode?: 'tag' \| 'flat'; name?: string }` |

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

Using the generated SDK works the same across modes. Construct a class with a client config (`baseURL`, `headers`, and the other `ClientConfig` fields), then call a method with the grouped options object (`{ path, query, headers, body }`) and read `data` off the result. The per-tag `PetClient` and `StoreClient` are identical with or without `sdk.name`. The name only adds a root that wires them together:

::: code-group

```typescript ['tag']
import { PetClient } from './src/gen/clients/petClient'
import { StoreClient } from './src/gen/clients/storeClient'

const config = { baseURL: 'https://petstore.swagger.io/v2' }
const pet = new PetClient(config)
const store = new StoreClient(config)

const { data } = await pet.getPetById({ path: { petId: 1 } })
await store.placeOrder({ body: { petId: 1, quantity: 1 } })
```

```typescript ['tag' + sdk.name]
// PetClient and StoreClient are the same as the 'tag' tab. `sdk.name` only adds
// the PetStore root that constructs them from one shared config.
import { PetStore } from './src/gen/clients/petStore'

const api = new PetStore({ baseURL: 'https://petstore.swagger.io/v2' })

const { data } = await api.pet.getPetById({ path: { petId: 1 } })
await api.store.placeOrder({ body: { petId: 1, quantity: 1 } })
```

```typescript ['flat']
import { PetStore } from './src/gen/clients/petStore'

const api = new PetStore({ baseURL: 'https://petstore.swagger.io/v2' })

const { data } = await api.getPetById({ path: { petId: 1 } })
await api.placeOrder({ body: { petId: 1, quantity: 1 } })
```

:::

Each call resolves to `{ status, data, error, contentType, request, response }`. Because `throwOnError` defaults to `true`, a resolved call means the request succeeded and `data` is set. Pass `throwOnError: false` on a call to get the discriminated union instead. Every variant is keyed on the top-level `status`, so a check on it narrows `data` on a success code and `error` on a documented error code, the same typed union you get for `data` on the success path:

```typescript
const { status, data, error } = await pet.getPetById({ path: { petId: 1 }, throwOnError: false })

if (status === 200) {
  console.log(data) // data is the success body, error is undefined
} else {
  console.error(status, error) // status is the documented error code, error is its parsed body
}
```

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

For example, `override: [{ type: 'tag', pattern: 'user', options: { validator: 'zod' } }]` turns on Zod validation for the `user` tag while the rest of the spec keeps the plugin default.

### resolver

Changes how the plugin names generated files and functions. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so you can call `this.default.name(name)` to reuse the built-in name.

|          |                                                      |
| -------: | :--------------------------------------------------- |
|    Type: | `Partial<ResolverClient> & ThisType<ResolverClient>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.
>
> See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the plugin default.

For example, `resolver: { name(name) { return \`api${this.default.name(name)}\` } }` prefixes every generated function name with `api`. The default resolver for this plugin is `resolverClient`, shared with `@kubb/plugin-fetch`.

### macros

Rewrites AST nodes before the plugin prints them to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback, such as `schema` or `operation`, receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginAxios } from '@kubb/plugin-axios'

pluginAxios({
  macros: [
    {
      name: 'prefix-operation-id',
      operation(node) {
        return { ...node, operationId: `api_${node.operationId}` }
      },
    },
  ],
})
```
