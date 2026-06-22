---
layout: doc
title: Kubb MSW Plugin
description: Generate MSW request handlers from OpenAPI so you can mock the
  entire API in tests and during local development.
outline: 2
kind: plugin
id: plugin-msw
name: MSW
category: mocks
type: official
npmPackage: "@kubb/plugin-msw"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-msw
featured: false
icon:
  light: https://kubb.dev/feature/msw.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - msw
  - mock-service-worker
  - api-mocking
  - mocks
  - testing
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-faker
resources:
  documentation: https://kubb.dev/plugins/plugin-msw
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-msw/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/msw
---

# @kubb/plugin-msw

`@kubb/plugin-msw` turns your OpenAPI spec into [MSW](https://mswjs.io/) request handlers. Drop them into a test setup or a service worker to mock the API. Each handler matches the spec's path, method, status, and response body. It builds on `@kubb/plugin-ts`, so keep `pluginTs()` in the plugins array.

By default a handler returns an empty typed payload you fill in from tests. Set `parser: 'faker'` to return generated data instead.

**See also**

- [MSW](https://mswjs.io/)
- [@kubb/plugin-ts](/plugins/plugin-ts)
- [@kubb/plugin-faker](/plugins/plugin-faker)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-msw@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-msw@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-msw@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-msw@beta
```

:::

## Options

### output

Where the generated handlers are written and how they are exported.

|           |                                                   |
| --------: | :------------------------------------------------ |
|     Type: | `Output`                                          |
| Required: | `false`                                           |
|  Default: | `{ path: 'handlers', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'handlers.ts'`.

|           |              |
| --------: | :----------- |
|     Type: | `string`     |
| Required: | `true`       |
|  Default: | `'handlers'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      output: { path: './handlers' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── handlers/
        ├── listPets.ts
        └── createPets.ts
```

:::

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'handlers.ts'`).

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

### handlers

Emits a `handlers.ts` file that re-exports every generated handler in one array. Spread it into your MSW `setupServer(...handlers)` or `setupWorker(...handlers)` call.

|           |           |
| --------: | :-------- |
|     Type: | `boolean` |
| Required: | `false`   |
|  Default: | `false`   |

::: code-group

```typescript [gen/handlers.ts]
import { listPetsHandler } from './listPetsHandler'
import { createPetsHandler } from './createPetsHandler'

export const handlers = [listPetsHandler(), createPetsHandler()] as const
```

```typescript [setup.ts]
import { setupServer } from 'msw/node'
import { handlers } from './gen/handlers'

export const server = setupServer(...handlers)
```

:::

### baseURL

URL added in front of every handler's request URL. When omitted, the URL comes from the adapter's server URL, usually the spec's `servers[0].url`. Set it to point at a different environment than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      baseURL: 'https://petstore.swagger.io/v2',
    }),
  ],
})
```

:::

### parser

Source of the response body each handler returns.

- `'data'` (default) returns an empty typed payload from `@kubb/plugin-ts`. You fill it in from tests.
- `'faker'` returns a value built by `@kubb/plugin-faker`. Add `pluginFaker()` to the plugins array. The plugin depends on Faker only when you choose this value.

|           |                     |
| --------: | :------------------ |
|     Type: | `'data' \| 'faker'` |
| Required: | `false`             |
|  Default: | `'data'`            |

::: code-group

```typescript ['data' (default)]
export function listPets(data?: ListPetsQueryResponse | ((info: ...) => Response | Promise<Response>)) {
  return http.get(`/pets`, function handler(info) {
    if (typeof data === 'function') return data(info)

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

```typescript ['faker']
export function listPets(data?: ListPetsQueryResponse | ((info: ...) => Response | Promise<Response>)) {
  return http.get('/pets', function handler(info) {
    if (typeof data === 'function') return data(info)

    return new Response(JSON.stringify(data || listPetsQueryResponse(data)), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

:::

### group

Splits generated files into subfolders so related handlers share a directory. Without `group`, every file lands directly in `output.path`. With `group`, files go under `{output.path}/{groupName}/`.

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
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
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
│   └── getPet.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the first tag on the operation (`operation.getTags().at(0)?.name`) and uses it as the group key. Operations without a tag fall back to a default group.
- `'path'` uses the first segment of the operation's URL as the group key.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder name from a group key. By default `'tag'` groups use the camelCased tag and `'path'` groups use the camelCased first path segment.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                  |

### include

Generates only the operations that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

- `tag`: the operation's first tag in the OpenAPI spec.
- `operationId`: the operation's `operationId`.
- `path`: the URL path, such as `'/pet/{petId}'`.
- `method`: the HTTP method, such as `'get'` or `'post'`.
- `contentType`: the request or response media type, such as `'application/json'`.
- `schemaName`: the component schema name under `#/components/schemas`.

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
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
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

Skips any operation that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

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
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
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

Applies different plugin options to operations that match a pattern. Use it for the few endpoints that need special treatment. Each entry takes the same `type` and `pattern` as `include` and `exclude`, plus an `options` object. That object accepts any plugin option except `override`, so rules cannot nest. Entries run top to bottom. The first match merges onto the plugin defaults, and later entries do not stack.

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

```typescript [Use Faker data for the user tag only]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFaker(),
    pluginMsw({
      parser: 'data',
      override: [
        {
          type: 'tag',
          pattern: 'user',
          options: { parser: 'faker' },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverMsw> & ThisType<ResolverMsw>` |
| Required: | `false`                                        |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript [Add a Mock prefix to every handler name]
import { defineConfig } from 'kubb'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMsw({
      resolver: {
        resolveName(name) {
          return `Mock${this.default(name, 'function')}`
        },
      },
    }),
  ],
})
```

The default resolver names every handler with a `Handler` suffix and always names the aggregate export `handlers`. Each plugin ships with a default resolver:

| Plugin                 | Default resolver  |
| ---------------------- | ----------------- |
| `@kubb/plugin-ts`      | `resolverTs`      |
| `@kubb/plugin-zod`     | `resolverZod`     |
| `@kubb/plugin-faker`   | `resolverFaker`   |
| `@kubb/plugin-cypress` | `resolverCypress` |
| `@kubb/plugin-msw`     | `resolverMsw`     |
| `@kubb/plugin-mcp`     | `resolverMcp`     |
| `@kubb/plugin-axios`   | `resolverClient`  |
| `@kubb/plugin-fetch`   | `resolverClient`  |

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Prefix every operationId]
import { defineConfig } from 'kubb'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMsw({
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

This plugin always depends on [`@kubb/plugin-ts`](/plugins/plugin-ts), so keep `pluginTs()` in the plugins array.

It depends on [`@kubb/plugin-faker`](/plugins/plugin-faker) only when you set `parser: 'faker'`. With the default `parser: 'data'`, Faker is not needed.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      output: { path: './mocks' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Service`,
      },
      handlers: true,
    }),
  ],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-msw/CHANGELOG.md)
