---
layout: doc
title: Kubb MCP Plugin
description: Generate a Model Context Protocol (MCP) server from OpenAPI so AI
  assistants like Claude can call your API as tools.
outline: 2
kind: plugin
id: plugin-mcp
name: MCP
category: ai
type: official
npmPackage: "@kubb/plugin-mcp"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-mcp
featured: false
icon:
  light: https://kubb.dev/feature/mcp-light.svg
  dark: https://kubb.dev/feature/mcp-dark.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - mcp
  - model-context-protocol
  - ai
  - claude
  - llm
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-client
  - plugin-zod
resources:
  documentation: https://kubb.dev/plugins/plugin-mcp
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/mcp
---

# @kubb/plugin-mcp

`@kubb/plugin-mcp` turns your OpenAPI spec into a [Model Context Protocol](https://modelcontextprotocol.io/introduction) server. Each operation becomes one MCP tool. AI assistants like Claude Desktop and Claude Code call those tools to reach your API. The plugin generates the tool handlers, the request code, and the Zod schemas that validate each call.

It builds on `@kubb/plugin-ts` and `@kubb/plugin-zod`, so add both to your config.

**See also**

- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop)

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-mcp@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-mcp@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-mcp@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-mcp@beta
```

:::

## Options

### output

Where the generated handlers are written and how they are exported.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Output`                                     |
| Required: | `false`                                      |
|  Default: | `{ path: 'mcp', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mcp.ts'`.

|           |         |
| --------: | :------ |
|     Type: | `string` |
| Required: | `true`  |
|  Default: | `'mcp'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
      output: { path: './mcp' },
    }),
  ],
})
```

```text [Resulting tree]
src/
└── gen/
    └── mcp/
        ├── addPetHandler.ts
        └── getPetByIdHandler.ts
```

:::

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'mcp.ts'`).

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
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
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
│   ├── addPetHandler.ts
│   └── getPetByIdHandler.ts
└── store/
    ├── getInventoryHandler.ts
    └── placeOrderHandler.ts
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

### client

HTTP client each handler uses to call the underlying API. It mirrors a subset of `pluginClient` options.

|           |                                                                              |
| --------: | :--------------------------------------------------------------------------- |
|     Type: | `ClientImportPath & { clientType?, dataReturnType?, baseURL?, paramsCasing? }` |
| Required: | `false`                                                                      |

#### client.client

Built-in HTTP client the handlers import. `'axios'` imports from `@kubb/plugin-client/clients/axios` and needs `axios` at runtime. `'fetch'` imports from `@kubb/plugin-client/clients/fetch` and uses the global `fetch`. Set `client.importPath` instead when you want a custom module, since `client` and `importPath` are mutually exclusive.

|           |                      |
| --------: | :------------------- |
|     Type: | `'axios' \| 'fetch'` |
| Required: | `false`              |
|  Default: | `'axios'`            |

#### client.importPath

Path or module specifier of a custom client module. Generated code imports its HTTP runtime from here instead of `@kubb/plugin-client/clients/{client}`. Use it to inject auth headers, add interceptors, set the base URL at runtime, or wrap a different HTTP library (ky, ofetch, and so on). Both relative paths (`./src/client.ts`) and bare specifiers (`@my-org/api-client`) work.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

> [!TIP]
> See the [custom client guide](https://kubb.dev/plugins/plugin-client#importpath) for a worked example.

#### client.clientType

Shape of the underlying client the handlers call into. Mirrors `pluginClient`'s `clientType` option.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `'function' \| 'class' \| 'staticClass'` |
| Required: | `false`                                  |
|  Default: | `'function'`                             |

#### client.dataReturnType

Shape of the value returned from each generated client function.

- `'data'` (default) returns only the response body (`response.data`).
- `'full'` returns a discriminated union keyed by HTTP status code. Each member is `{ status: N; data: StatusNType; statusText: string }`. Narrowing on `res.status` also narrows `res.data` to the matching response type.

|           |                    |
| --------: | :----------------- |
|     Type: | `'data' \| 'full'` |
| Required: | `false`            |
|  Default: | `'data'`           |

#### client.baseURL

Base URL prepended to every request URL in the generated client. When omitted, the URL comes from the spec's `servers[0].url`. Set it to point the client at a different environment (staging, production) than the spec.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

#### client.paramsCasing

Renames parameter properties passed to the underlying client. Mirrors `pluginClient`'s `paramsCasing` option.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

### paramsCasing

Renames parameter properties in the generated handlers to camelCase. The HTTP layer still uses the original spec names, and Kubb writes the mapping for you.

|           |               |
| --------: | :------------ |
|     Type: | `'camelcase'` |
| Required: | `false`       |

> [!IMPORTANT]
> Set the same `paramsCasing` here as on `@kubb/plugin-ts` so the handlers' parameter types line up with the generated request types.

::: code-group

```typescript [With paramsCasing: 'camelcase']
// Handler signature uses camelCase
export async function findPetsByStatusHandler({ stepId }: { stepId: FindPetsByStatusPathParams['stepId'] }): Promise<CallToolResult> {
  const step_id = stepId

  const res = await fetch({
    method: 'GET',
    url: `/pet/findByStatus/${step_id}`,
  })
  // ...
}
```

```typescript [Without paramsCasing]
export async function findPetsByStatusHandler({ step_id }: { step_id: FindPetsByStatusPathParams['step_id'] }): Promise<CallToolResult> {
  const res = await fetch({
    method: 'GET',
    url: `/pet/findByStatus/${step_id}`,
  })
  // ...
}
```

:::

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
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
      include: [{ type: 'tag', pattern: 'pet' }],
    }),
  ],
})
```

```typescript [Only GET operations under /pet]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
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
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
      exclude: [{ type: 'tag', pattern: 'store' }],
    }),
  ],
})
```

```typescript [Skip a specific operation and all delete methods]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
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
  options: Partial<Options>
}
```

::: code-group

```typescript [Send the admin tag to its own folder]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
      output: { path: './mcp' },
      override: [
        {
          type: 'tag',
          pattern: 'admin',
          options: { output: { path: './mcp/admin' } },
        },
      ],
    }),
  ],
})
```

:::

### resolver

Changes how the plugin names generated files and handlers. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Partial<ResolverMcp> & ThisType<ResolverMcp>` |
| Required: | `false`                                        |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

```typescript [Prefix every handler name with "Mcp"]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
      resolver: {
        resolveName(name) {
          return `Mcp${this.default(name, 'function')}`
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

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

::: code-group

```typescript [Strip descriptions before printing]
import { defineConfig } from 'kubb'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
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
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginMcp({
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

This plugin needs two other plugins. Kubb runs them before `plugin-mcp` so the handlers can import the generated types and Zod schemas.

- [`@kubb/plugin-ts`](/plugins/plugin-ts)
- [`@kubb/plugin-zod`](/plugins/plugin-zod)

[`@kubb/plugin-client`](/plugins/plugin-client) is optional. Add it to share one client across plugins. Leave it out and `plugin-mcp` injects its own client into `.kubb/client.ts`.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginClient(),
    pluginZod(),
    pluginMcp({
      output: { path: 'mcp', barrel: { type: 'named' } },
      client: {
        baseURL: 'https://petstore.swagger.io/v2',
      },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Handlers`,
      },
    }),
  ],
})
```

:::

## See Also

- [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md)
