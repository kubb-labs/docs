---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-swr.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'hooks' }` | Where the generated hooks are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`client`](#client) | `'fetch' \| 'axios'` | — | Which registered client plugin the hooks call |
| [`query`](#query) | `Partial<Query> \| false` | `{ methods: ['get'], importPath: 'swr' }` | Configure the `useSWR` hooks, or turn them off |
| [`queryKey`](#querykey) | `Transformer` | — | Build the SWR key for each query hook |
| [`mutation`](#mutation) | `Partial<Mutation> \| false` | `{ methods: ['post', 'put', 'patch', 'delete'], importPath: 'swr/mutation' }` | Configure the `useSWRMutation` hooks, or turn them off |
| [`mutationKey`](#mutationkey) | `Transformer` | — | Build the SWR key for each mutation hook |
| [`validator`](#validator) | `false \| 'zod' \| { request?: 'zod', response?: 'zod' }` | `false` | Validate request and response data with Zod schemas |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverSwr>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'hooks', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'hooks.ts'`.

|          |           |
| -------: | :-------- |
|    Type: | `string`  |
| Default: | `'hooks'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'hooks.ts'`).

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
// src/gen/hooks/index.ts
export { useGetPetById } from './useGetPetById'
export { useAddPet } from './useAddPet'
```

```typescript ['all']
// src/gen/hooks/index.ts
export * from './useGetPetById'
export * from './useAddPet'
```

```text [nested]
src/gen/hooks/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports useGetPetById, useAddPet, ...
│   └── useGetPetById.ts
└── store/
    ├── index.ts
    └── useGetInventory.ts
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
import useSWR from 'swr'
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
src/gen/hooks/
├── pet/
│   ├── useAddPet.ts
│   └── useGetPetById.ts
└── store/
    ├── useGetInventory.ts
    └── useGetOrderById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Hooks` to the group keeps a `petHooks/` layout.

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
| Default: | `(ctx) => \`${ctx.group}\``         |

### client

Selects which registered client plugin the generated hooks call. Every client plugin speaks the same request contract, so the hooks call a contract function that takes one grouped `options` object.

- `'fetch'` calls the `@kubb/plugin-fetch` functions.
- `'axios'` calls the `@kubb/plugin-axios` functions.

When a single client plugin is registered, the plugin auto-detects it, so you only need `client` to disambiguate when several client plugins are in the config. A client plugin must be registered, since the hooks always call its function.

|          |                      |
| -------: | :------------------- |
|    Type: | `'fetch' \| 'axios'` |

### query

Configures the generated `useSWR` hooks. The plugin generates them by default. Pass an object to change the HTTP methods or the import path. Pass `false` to skip query hook generation.

|          |                           |
| -------: | :------------------------ |
|    Type: | `Partial<Query> \| false` |
| Default: | `{ methods: ['get'], importPath: 'swr' }` |

#### query.methods

HTTP methods treated as queries. An operation whose method is in this list generates a `useSWR` hook instead of a mutation.

|          |                 |
| -------: | :-------------- |
|    Type: | `Array<string>` |
| Default: | `['get']`       |

#### query.importPath

Module that `useSWR` is imported from. The plugin emits `import useSWR from '${importPath}'`. It accepts relative and absolute paths and uses the value as written. Relative paths resolve against the generated file.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'swr'`  |

Changing `importPath` rewrites the import at the top of every query hook:

::: code-group

```typescript ['swr' (default)]
import useSWR from 'swr'
```

```typescript ['custom/swr']
import useSWR from 'custom/swr'
```

:::

You call the generated hook the same way no matter the import path. Only the `useSWR` import inside the hook changes:

```typescript
import { useGetPetById } from './src/gen/hooks/useGetPetById'

const { data, error, isLoading } = useGetPetById({ path: { petId: 1 } })
```

### queryKey

Builds the SWR key for each query hook. The callback receives the operation `node` and the active `casing`, and returns the key array. The plugin uses its built-in transformer when this is unset.

|          |               |
| -------: | :------------ |
|    Type: | `Transformer` |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### mutation

Configures the generated `useSWRMutation` hooks. The plugin generates them by default. Pass an object to change the HTTP methods or the import path. Pass `false` to skip mutation hook generation.

|          |                              |
| -------: | :--------------------------- |
|    Type: | `Partial<Mutation> \| false` |
| Default: | `{ methods: ['post', 'put', 'patch', 'delete'], importPath: 'swr/mutation' }` |

#### mutation.methods

HTTP methods treated as mutations. An operation whose method is in this list generates a `useSWRMutation` hook instead of a query.

|          |                                      |
| -------: | :----------------------------------- |
|    Type: | `Array<string>`                      |
| Default: | `['post', 'put', 'patch', 'delete']` |

#### mutation.importPath

Module that `useSWRMutation` is imported from. The plugin emits `import useSWRMutation from '${importPath}'`. It accepts relative and absolute paths and uses the value as written. Relative paths resolve against the generated file.

|          |                  |
| -------: | :--------------- |
|    Type: | `string`         |
| Default: | `'swr/mutation'` |

Changing `importPath` rewrites the import at the top of every mutation hook:

::: code-group

```typescript ['swr/mutation' (default)]
import useSWRMutation from 'swr/mutation'
```

```typescript ['custom/mutation']
import useSWRMutation from 'custom/mutation'
```

:::

You call the generated hook the same way no matter the import path. Only the `useSWRMutation` import inside the hook changes:

```typescript
import { useAddPet } from './src/gen/hooks/useAddPet'

const { trigger } = useAddPet()
```

### mutationKey

Builds the SWR key for each mutation hook. The callback receives the operation `node` and the active `casing`, and returns the key array. The plugin uses its built-in transformer when this is unset.

|          |               |
| -------: | :------------ |
|    Type: | `Transformer` |

> [!WARNING]
> String values are inlined verbatim into generated code. Wrap any literal string in `JSON.stringify(...)`.

### validator

Runtime validator applied to request and response data using schemas from `@kubb/plugin-zod`.

- `false` (default) does no validation. The hook returns the response cast to the generated type.
- `'zod'` validates the response body only.
- `{ request?: 'zod', response?: 'zod' }` opts in per direction. `request` validates the request body and query parameters before the call. `response` validates the response body after.

Add `@kubb/plugin-zod` to the plugins list when either direction is `'zod'`.

|          |                                                           |
| -------: | :-------------------------------------------------------- |
|    Type: | `false \| 'zod' \| { request?: 'zod', response?: 'zod' }` |
| Default: | `false`                                                   |

::: code-group

```typescript [false (default)]
// no validation, response is cast to the generated type
const { data } = useGetPetById({ path: { petId: 1 } })
```

```typescript ['zod']
// the response body is parsed with the generated Zod schema
const { data } = useGetPetById({ path: { petId: 1 } })
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

For example, `override: [{ type: 'tag', pattern: 'user', options: { validator: 'zod' } }]` turns on response validation for the `user` tag while the rest of the spec keeps the plugin default.

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|          |                                                |
| -------: | :--------------------------------------------- |
|    Type: | `Partial<ResolverSwr> & ThisType<ResolverSwr>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.

For example, `resolver: { resolveName(name) { return \`swr${this.default(name, 'function')}\` } }` prefixes every generated hook name with `swr`.

The plugin ships with `resolverSwr` as its default resolver.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginSwr } from '@kubb/plugin-swr'

pluginSwr({
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
