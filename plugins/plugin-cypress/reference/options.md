---
layout: doc
title: Options
description: All configuration options for @kubb/plugin-cypress.
outline: deep
---

# Options

### output

Where the generated helpers are written and how they are exported.

|           |                                                  |
| --------: | :----------------------------------------------- |
|     Type: | `Output`                                         |
| Required: | `false`                                          |
|  Default: | `{ path: 'cypress', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'cypress.ts'`.

|           |             |
| --------: | :---------- |
|     Type: | `string`    |
| Required: | `true`      |
|  Default: | `'cypress'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'cypress.ts'`).

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

### baseURL

URL added in front of every request URL. When omitted, the URL comes from the adapter's server URL, usually the spec's `servers[0].url`. Set it to point the helpers at a different environment, such as staging or production.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |

### group

Splits generated files into subfolders by the operation's first tag or first path segment. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

> [!TIP]
> Use `group` to mirror your API's domain structure (pet, store, user) in the generated code. Combine it with `output.barrel: { type: 'named', nested: true }` to get per-group barrel files.
>
> `group` only applies to `output.mode: 'directory'` (the default). It is not valid with `output.mode: 'file'`, since a single-file output has no grouping concept.

With `group: { type: 'tag' }`, the generator emits one folder per tag, named after the camelCased tag:

```text [Resulting tree]
src/gen/
├── pet/
│   ├── addPet.ts
│   └── getPetById.ts
└── store/
    ├── createStore.ts
    └── getStoreById.ts
```

Pass `group.name` to customize the folder name. For example, ``name: ({ group }) => `${group}Controller` `` keeps the pre-v5 `petController/` layout.

#### group.type

Property used to assign each operation to a group. Required whenever `group` is set.

- `'tag'` reads the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` reads the first segment of the operation's URL (`/pet/findByStatus` becomes `pet`).

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that builds the folder name from the group key (the operation's first tag or first path segment).

|           |                                           |
| --------: | :---------------------------------------- |
|     Type: | `(context: { group: string }) => string`  |
| Required: | `false`                                   |
|  Default: | camelCased tag, or first path segment for `path` groups |

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

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                                        |
| --------: | :----------------------------------------------------- |
|     Type: | `Partial<ResolverCypress> & ThisType<ResolverCypress>` |
| Required: | `false`                                                |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. To change the AST nodes themselves, such as stripping descriptions, use `macros` instead.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                |
| --------: | :------------- |
|     Type: | `Array<Macro>` |
| Required: | `false`        |

> [!TIP]
> Use `macros` to rewrite node properties before printing. To change the names of generated symbols and files, use `resolver` instead.

