---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'cypress', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`baseURL`](#baseurl) | `string` | — | Base URL prepended to every request |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverCypress>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |

### output

Where the generated `.ts` files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'cypress', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'cypress.ts'`.

|          |             |
| -------: | :---------- |
|    Type: | `string`    |
| Default: | `'cypress'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'cypress.ts'`).

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
// src/gen/cypress/index.ts
export { getPetById } from './getPetById'
export { addPet } from './addPet'
```

```typescript ['all']
// src/gen/cypress/index.ts
export * from './getPetById'
export * from './addPet'
```

```text [nested]
src/gen/cypress/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports getPetById, addPet, ...
│   └── getPetById.ts
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

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from a `BannerMeta` object. The meta carries the document info (`title`, `description`, `version`, `baseURL`) plus the per-file context `filePath`, `baseName`, `isBarrel`, and `isAggregation`, so a directive such as `'use server'` can skip barrel files.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

A function banner builds the text from the meta, such as `banner: (meta) => \`// Source: ${meta.filePath}\``.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the same `BannerMeta` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|          |                                          |
| -------: | :--------------------------------------- |
|    Type: | `string \| ((meta: BannerMeta) => string)` |

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
src/gen/cypress/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name. For example, a `name` function that appends `Requests` to the group produces a `petRequests/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

An operation with no tag goes in the `default` group.

|          |                   |
| -------: | :---------------- |
|    Type: | `'tag' \| 'path'` |

#### group.name

Function that turns a group key into a folder name. For `'tag'` groups the key is the camelCased tag, and for `'path'` groups it is the first path segment. The result is used as the subdirectory name under `output.path`.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: { group: string }) => string` |
| Default: | camelCased tag, or first path segment for `path` groups |

### baseURL

Base URL prepended to every request in the generated helpers. When omitted, the URL comes from the adapter's server URL, usually the spec's `servers[0].url`. Set it to point the helpers at a different environment, such as staging or production.

|          |          |
| -------: | :------- |
|    Type: | `string` |

::: code-group

```typescript [Without baseURL]
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

```typescript [baseURL: 'https://staging.petstore.dev']
export function showPetById(
  { path }: ShowPetByIdRequestConfig,
  options: Partial<Cypress.RequestOptions> = {},
): Cypress.Chainable<ShowPetByIdResponse> {
  return cy
    .request<ShowPetByIdResponse>({
      method: 'GET',
      url: `https://staging.petstore.dev/pets/${path.petId}`,
      ...options,
    })
    .then((res) => res.body)
}
```

:::

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

For example, `override: [{ type: 'tag', pattern: 'user', options: { baseURL: 'https://users.petstore.dev' } }]` points the `user` tag at a different host while the rest of the spec keeps the plugin default.

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so you can call `this.core.name(name)` to reuse the built-in name.

|          |                                                        |
| -------: | :----------------------------------------------------- |
|    Type: | `Partial<ResolverCypress> & ThisType<ResolverCypress>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.

For example, `resolver: { resolveName(name) { return \`api${this.core.name(name)}\` } }` prefixes every generated helper name with `api`.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginCypress } from '@kubb/plugin-cypress'

pluginCypress({
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
