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

The bundled `client` also exposes a `buildUrl` method. It returns the final URL for an operation from the base URL, the interpolated path params, and the serialized query, without sending the request. This helps when you build cache keys, prefetch data, or render links:

```ts
import { client } from './.kubb/client'

const url = client.buildUrl({ url: '/pet/{petId}', path: { petId: 1 }, query: { status: ['available'] } })
// '/pet/1?status=available'
```

**See also**

- [axios](https://axios-http.com/)
- [`@kubb/plugin-ts`](/plugins/plugin-ts)

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

Where the generated functions are written and how they are exported.

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

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      output: { path: './clients' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── clients/
        ├── addPet.ts
        └── getPetById.ts
```

:::

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'clients.ts'`).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

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

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      group: { type: 'tag' },
    }),
  ],
})
```

:::

With the configuration above, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    ├── getInventory.ts
    └── placeOrder.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Controller` to the group keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the first tag on the operation (`operation.getTags().at(0)?.name`). Operations without a tag go in a default group.
- `'path'` reads the first segment of the operation's URL.

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

```typescript [Type definition]
export type Exclude = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

::: code-group

```typescript [Skip everything under the store tag]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

:::

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`) as `exclude`.

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
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      include: [{ type: 'tag', pattern: 'pet' }],
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
  options: Partial<Options>
}
```

::: code-group

```typescript [Send the admin tag to its own folder]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      output: { path: './clients' },
      override: [
        {
          type: 'tag',
          pattern: 'admin',
          options: { output: { path: './clients/admin' } },
        },
      ],
    }),
  ],
})
```

:::

### baseURL

Base URL prepended to every request the functions make. When omitted, the URL comes from the adapter's server URL (`servers[0].url` in the spec). Set it to point the client at a different environment (staging, production) than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### parser

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`.

- `false` (default) does no validation. The client returns the response cast to the generated type.
- `'zod'` validates response bodies only.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction. `request` validates the request body before the call. `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`.

|           |                                                           |
| --------: | :-------------------------------------------------------- |
|     Type: | `false \| 'zod' \| { request?: 'zod'; response?: 'zod' }` |
| Required: | `false`                                                   |
|  Default: | `false`                                                   |

### sdk

Generates a class-based SDK instead of standalone functions. Leave `sdk` unset to keep the per-operation functions, which is what the query plugins consume.

- `mode: 'tag'` (default) emits one instance class per tag.
- `mode: 'tag'` with `name` emits a composed root class that instantiates every tag client from one config.
- `mode: 'flat'` emits a single class named by `name` with every operation as a direct method.

|           |                                       |
| --------: | :------------------------------------ |
|     Type: | `{ mode?: 'tag' \| 'flat'; name?: string }` |
| Required: | `false`                               |

::: code-group

```typescript [Standalone functions (sdk unset)]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginAxios()],
})
```

```typescript [One class per tag]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      sdk: {},
    }),
  ],
})
```

```typescript [Composed root class]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      sdk: { name: 'petStore' },
    }),
  ],
})
```

```typescript [Single flat class]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      sdk: { name: 'petStore', mode: 'flat' },
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and functions. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                      |
| --------: | :--------------------------------------------------- |
|     Type: | `Partial<ResolverClient> & ThisType<ResolverClient>` |
| Required: | `false`                                              |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript [Prefix every function name with "Api"]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      resolver: {
        resolveName(name) {
          return `Api${this.default(name, 'function')}`
        },
      },
    }),
  ],
})
```

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
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
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
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

## Authentication

The generated functions carry the security schemes from your spec, so you configure credentials in one place. Set an `auth` resolver on the client config and the runtime attaches a bearer, basic, or apiKey token to every guarded call.

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  auth: () => localStorage.getItem('token') ?? undefined,
})
```

See the [authentication guide](/docs/5.x/guides/authentication) for the full scheme mapping, per-instance clients, and per-call overrides.

## Dependencies

This plugin needs `@kubb/plugin-ts` in your config. Kubb runs it before `plugin-axios` so the functions can import the generated types.

- [`@kubb/plugin-ts`](/plugins/plugin-ts)

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

## See Also

- [axios](https://axios-http.com/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-axios/CHANGELOG.md)
