---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-mcp.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'mcp', barrel: { type: 'named' } }` | Where the generated handlers are written and exported |
| [`client`](#client) | `'fetch' \| 'axios'` | — | Which registered client plugin the handlers call |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverMcp>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated MCP handler files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'mcp', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'mcp.ts'`.

|          |         |
| -------: | :------ |
|    Type: | `string`  |
| Default: | `'mcp'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'mcp.ts'`).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'directory' \| 'file'` |
| Default: | `'directory'`           |

> [!TIP]
> Pair `'directory'` with the `group` option to organize output into per-tag or per-path subdirectories. `mode: 'file'` forbids `group`. A single-file output has nothing to group, and combining them stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### output.barrel

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
// src/gen/mcp/index.ts
export { addPetHandler } from './addPetHandler'
export { getPetByIdHandler } from './getPetByIdHandler'
export { getServer, server, startServer } from './server'
```

```typescript ['all']
// src/gen/mcp/index.ts
export * from './addPetHandler'
export * from './getPetByIdHandler'
export * from './server'
```

```text [nested]
src/gen/mcp/
├── index.ts          # re-exports ./pet, ./store, and ./server
├── server.ts
├── .mcp.json
├── pet/
│   ├── index.ts      # re-exports addPetHandler, getPetByIdHandler, ...
│   └── addPetHandler.ts
└── store/
    ├── index.ts
    └── getInventoryHandler.ts
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

### client

Selects which registered client plugin the handlers call. Each handler calls that client's generated function for the operation, passing one grouped `{ path, query, headers, body }` object.

- `'axios'` calls the functions from `@kubb/plugin-axios`.
- `'fetch'` calls the functions from `@kubb/plugin-fetch`.

When you register a single client plugin, the plugin auto-detects it, so you only set this string to disambiguate when both are registered. One of those client plugins must be registered, since the handlers call its functions. Transport options such as `baseURL` live on that client plugin.

|          |                      |
| -------: | :------------------- |
|    Type: | `'axios' \| 'fetch'` |

### group

Splits generated files into subfolders by the operation's first tag or first path segment. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|          |         |
| -------: | :------ |
|    Type: | `Group` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get a barrel file per group.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── server.ts
├── .mcp.json
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

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key (the operation's first tag) into a folder name, used as the subdirectory name under `output.path`. The `server.ts` and `.mcp.json` files keep their fixed names at the root of `output.path`.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: { group: string }) => string` |
| Default: | `({ group }) => camelCase(group)` |

For `type: 'path'` groups, the default uses the first URL segment as-is instead of camelCasing.

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

For example, `override: [{ type: 'tag', pattern: 'user', options: { output: { path: 'mcp/user' } } }]` routes the `user` tag's handlers to their own folder.

> [!NOTE]
> `client` resolves once at setup, so it cannot be changed per override.

### resolver

Changes how the plugin names generated files and handlers. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so you can call `this.default.name(name)` to reuse the built-in name.

|          |                                                |
| -------: | :--------------------------------------------- |
|    Type: | `Partial<ResolverMcp> & ThisType<ResolverMcp>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.
>
> See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the plugin default.

For example, `resolver: { name(name) { return \`Api${this.default.name(name)}\` } }` prefixes every generated handler name with `Api`.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginMcp } from '@kubb/plugin-mcp'

pluginMcp({
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
