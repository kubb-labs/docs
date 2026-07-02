---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-msw.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'handlers' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every handler's request |
| [`handlers`](#handlers) | `boolean` | `false` | Emit a `handlers.ts` that re-exports every handler |
| [`parser`](#parser) | `'data' \| 'faker'` | `'data'` | Source of the response body each handler returns |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverMsw>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated handler files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'handlers', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'handlers.ts'`.

|          |              |
| -------: | :----------- |
|    Type: | `string`     |
| Default: | `'handlers'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'handlers.ts'`).

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
// src/gen/handlers/index.ts
export { getPet } from './getPet'
export { addPet } from './addPet'
```

```typescript ['all']
// src/gen/handlers/index.ts
export * from './getPet'
export * from './addPet'
```

```text [nested]
src/gen/handlers/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPet, addPet, ...
│   └── getPet.ts
└── store/
    ├── index.ts
    └── getStoreById.ts
```

```text [false]
# No index.ts is generated for this plugin.
# Its files are also excluded from the root index.ts.
```

:::

#### output.banner

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode` (the AST root with the path, schema, and operation context).

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((node: RootNode) => string)` |

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
import { http } from 'msw'

export function getPet(data?: GetPetQueryResponse) {
  // ...
}
```

A function banner builds the text from the file's `RootNode`, such as `banner: (node) => \`// Source: ${node.filePath}\``.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((node: RootNode) => string)` |

### group

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|          |         |
| -------: | :------ |
|    Type: | `Group` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-tag barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── addPet.ts
│   └── getPet.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Service` to the group renames each folder to `petService/`.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

Operations with no tag go in a default group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key (the operation's first tag) into a folder or identifier name. The result is used as both the subdirectory name under `output.path` and as a suffix when naming aggregate files.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: GroupContext) => string` |
| Default: | `(ctx) => camelCase(ctx.group)`         |

### baseURL

Base URL prepended to every handler's request. When omitted, the URL comes from the adapter's server URL, usually the spec's `servers[0].url`. Set it to point at a different environment than the spec.

|          |          |
| -------: | :------- |
|    Type: | `string` |

### handlers

Emits a `handlers.ts` file that re-exports every generated handler grouped by HTTP method. Spread it into your MSW `setupServer(...handlers)` or `setupWorker(...handlers)` call.

|          |           |
| -------: | :-------- |
|    Type: | `boolean` |
| Default: | `false`   |

::: code-group

```typescript [gen/handlers.ts]
import { getPet } from './getPet'
import { addPet } from './addPet'

export const handlers = [getPet(), addPet()] as const
```

```typescript [setup.ts]
import { setupServer } from 'msw/node'
import { handlers } from './gen/handlers'

export const server = setupServer(...handlers)
```

:::

### parser

Source of the response body each handler returns.

- `'data'` (default) returns a typed empty or example payload from `@kubb/plugin-ts`. You fill it in from tests.
- `'faker'` returns a value built by `@kubb/plugin-faker`. Register `pluginFaker()` in the plugins array. The plugin depends on Faker only when you choose this value.

|          |                     |
| -------: | :------------------ |
|    Type: | `'data' \| 'faker'` |
| Default: | `'data'`            |

The handler body changes with the parser. With `'data'` the caller passes the payload, while `'faker'` falls back to a generated mock:

::: code-group

```typescript ['data' (default)]
export function getPet(data?: GetPetQueryResponse) {
  return http.get('/pet/:petId', function handler(info) {
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

```typescript ['faker']
export function getPet(data?: GetPetQueryResponse) {
  return http.get('/pet/:petId', function handler(info) {
    return new Response(JSON.stringify(data || getPetQueryResponse()), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

:::

How you register the handler in a test depends on the value:

::: code-group

```typescript ['data' (default)]
import { setupServer } from 'msw/node'
import { getPet } from './src/gen/handlers/getPet'

// you pass the response payload yourself
const server = setupServer(getPet({ name: 'Fluffy' }))
```

```typescript ['faker']
import { setupServer } from 'msw/node'
import { getPet } from './src/gen/handlers/getPet'

// no payload needed, the handler returns generated mock data
const server = setupServer(getPet())
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

For example, `override: [{ type: 'tag', pattern: 'user', options: { parser: 'faker' } }]` returns generated data for the `user` tag while the rest of the spec keeps the default `parser: 'data'`.

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|          |                                                |
| -------: | :--------------------------------------------- |
|    Type: | `Partial<ResolverMsw> & ThisType<ResolverMsw>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.

The default resolver names every handler with a `Handler` suffix and always names the aggregate export `handlers`.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginMsw } from '@kubb/plugin-msw'

pluginMsw({
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
