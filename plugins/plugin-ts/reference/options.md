---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-ts.
outline: deep
---

# Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'types', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`enum`](#enum) | `EnumOptions` | `{ type: 'asConst', … }` | How enums are generated and cased |
| [`syntaxType`](#syntaxtype) | `'type' \| 'interface'` | `'type'` | Emit object schemas as type aliases or interfaces |
| [`optionalType`](#optionaltype) | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` | `'questionToken'` | How optional properties are written |
| [`arrayType`](#arraytype) | `'array' \| 'generic'` | `'array'` | `Type[]` or `Array<Type>` |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `Partial<ResolverTs>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |
| [`printer`](#printer) | `{ nodes?: PrinterTsNodes }` | — | Replace the handler for a schema type |

### output

Where the generated `.ts` files are written and how they are exported.

|          |                     |
| -------: | :------------------ |
|    Type: | `Output`            |
| Default: | `{ path: 'types', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'types.ts'`.

|          |           |
| -------: | :-------- |
|    Type: | `string`  |
| Default: | `'types'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (for example `'types.ts'`).

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
// src/gen/types/index.ts
export { Pet, PetStatus } from './Pet'
export { Store } from './Store'
```

```typescript ['all']
// src/gen/types/index.ts
export * from './Pet'
export * from './Store'
```

```text [nested]
src/gen/types/
├── index.ts          # re-exports ./pet and ./store
├── pet/
│   ├── index.ts      # re-exports Pet, Store, ...
│   └── Pet.ts
└── store/
    ├── index.ts
    └── Store.ts
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
export type Pet = {
  id: number
  name: string
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
src/gen/
├── pet/
│   ├── AddPet.ts
│   └── GetPet.ts
└── store/
    ├── CreateStore.ts
    └── GetStoreById.ts
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

Function that turns a group key (the operation's first tag) into a folder or identifier name. The result is used as both the subdirectory name under `output.path` and as a suffix when naming aggregate files.

|          |                                     |
| -------: | :---------------------------------- |
|    Type: | `(context: { group: string }) => string` |
| Default: | `({ group }) => camelCase(group)` |

For `type: 'path'` groups, the default uses the first URL segment as-is instead of camelCasing.

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

|          |                                                                                      |
| -------: | :----------------------------------------------------------------------------------- |
|    Type: | `EnumOptions`                                                                         |
| Default: | `{ type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' }` |

> [!TIP]
> Set `constCasing: 'pascalCase'` together with `typeSuffix: ''` to emit a const and a type that share the schema's exact name. This is the convention most hand-written codebases use, so migrating an existing project keeps every annotation and value reference intact.
>
> ```typescript
> export const PetStatus = {
>   available: 'available',
>   pending: 'pending',
>   sold: 'sold',
> } as const
>
> export type PetStatus = (typeof PetStatus)[keyof typeof PetStatus]
> ```

#### enum.type

How OpenAPI enums are represented in the generated TypeScript.

- `'asConst'` (default) generates an `as const` object plus a key/value type. It is tree-shakeable and adds no enum runtime.
- `'enum'` generates a regular TypeScript `enum`, which produces JavaScript runtime code.
- `'constEnum'` generates a `const enum`. It inlines at compile time and is not compatible with `--isolatedModules`.
- `'literal'` generates a plain union type (`'available' | 'pending' | 'sold'`) with no runtime value.
- `'inlineLiteral'` inlines the union at every usage site instead of giving it a name.

|          |                                                                     |
| -------: | :------------------------------------------------------------------ |
|    Type: | `'asConst' \| 'enum' \| 'constEnum' \| 'literal' \| 'inlineLiteral'` |
| Default: | `'asConst'`                                                         |

::: code-group

```typescript ['asConst' (default)]
export const petStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatusKey = (typeof petStatus)[keyof typeof petStatus]
```

```typescript ['enum']
export enum PetStatus {
  available = 'available',
  pending = 'pending',
  sold = 'sold',
}
```

```typescript ['constEnum']
export const enum PetStatus {
  available = 'available',
  pending = 'pending',
  sold = 'sold',
}
```

```typescript ['literal']
export type PetStatus = 'available' | 'pending' | 'sold'
```

```typescript ['inlineLiteral']
export type PetStatus = 'available' | 'pending' | 'sold'
```

:::

How you consume the enum depends on the representation:

::: code-group

```typescript ['asConst' (default)]
import { petStatus, type PetStatusKey } from './src/gen/types/PetStatus'

const status: PetStatusKey = petStatus.available // 'available'
```

```typescript ['enum']
import { PetStatus } from './src/gen/types/PetStatus'

const status: PetStatus = PetStatus.available
```

```typescript ['constEnum']
import { PetStatus } from './src/gen/types/PetStatus'

const status: PetStatus = PetStatus.available
```

```typescript ['literal']
import type { PetStatus } from './src/gen/types/PetStatus'

const status: PetStatus = 'available'
```

```typescript ['inlineLiteral']
// inlined on the owning type, with no separate alias to import
const status: 'available' | 'pending' | 'sold' = 'available'
```

:::

> [!TIP]
> `'inlineLiteral'` keeps the union out of a named alias. The values appear directly at each usage site, such as `status?: 'available' | 'pending' | 'sold'` on the owning type.

#### enum.constCasing

Casing of the generated const variable when `type` is `'asConst'`.

- `'camelCase'` names the const `petStatus`.
- `'pascalCase'` names the const `PetStatus`, matching the schema name.

|          |                               |
| -------: | :---------------------------- |
|    Type: | `'camelCase' \| 'pascalCase'` |
| Default: | `'camelCase'`                 |

::: code-group

```typescript ['camelCase' (default)]
export const petStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatusKey = (typeof petStatus)[keyof typeof petStatus]
```

```typescript ['pascalCase']
export const PetStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatusKey = (typeof PetStatus)[keyof typeof PetStatus]
```

:::

The const and its companion type are consumed the same way regardless of casing. Only the imported const name changes, here from `petStatus` to `PetStatus`:

```typescript
import { petStatus, type PetStatusKey } from './src/gen/types/PetStatus'

const status: PetStatusKey = petStatus.available // 'available'
```

#### enum.typeSuffix

Suffix appended to the type alias generated for enums when `type` is `'asConst'`.

The const object name (for example `petStatus`) is unaffected, so only the companion type alias is renamed. Set it to `''` to drop the suffix, which (with `constCasing: 'pascalCase'`) merges the const and type under one name.

|          |          |
| -------: | :------- |
|    Type: | `string` |
| Default: | `'Key'`  |

::: code-group

```typescript ['Key' (default)]
export const petStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatusKey = (typeof petStatus)[keyof typeof petStatus]
```

```typescript ['Value']
export const petStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatusValue = (typeof petStatus)[keyof typeof petStatus]
```

```typescript ['' (no suffix)]
export const petStatus = {
  available: 'available',
  pending: 'pending',
  sold: 'sold',
} as const

export type PetStatus = (typeof petStatus)[keyof typeof petStatus]
```

:::

The const and its companion type are consumed the same way regardless of suffix. Only the type-alias name changes, here from `PetStatusKey` to `PetStatusValue`:

```typescript
import { petStatus, type PetStatusValue } from './src/gen/types/PetStatus'

const status: PetStatusValue = petStatus.available // 'available'
```

#### enum.keyCasing

Casing applied to enum key names. By default the key is the raw value from the spec. Switch to a project convention when needed.

|          |                                                                                |
| -------: | :----------------------------------------------------------------------------- |
|    Type: | `'screamingSnakeCase' \| 'snakeCase' \| 'pascalCase' \| 'camelCase' \| 'none'` |
| Default: | `'none'`                                                                       |

| Value                  | Example key  |
| ---------------------- | ------------ |
| `'screamingSnakeCase'` | `ENUM_VALUE` |
| `'snakeCase'`          | `enum_value` |
| `'pascalCase'`         | `EnumValue`  |
| `'camelCase'`          | `enumValue`  |
| `'none'` (default)     | as-is        |

### syntaxType

Whether object schemas are emitted as `type` aliases or `interface` declarations.

`type` is the safer default for generated code. Type aliases are closed, intersections work cleanly, and unions are fine. Pick `interface` only when consumers need declaration merging, which is rare for generated code. For more background, see [Type vs Interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use).

|          |                         |
| -------: | :---------------------- |
|    Type: | `'type' \| 'interface'` |
| Default: | `'type'`                |

::: code-group

```typescript ['type' (default)]
export type Pet = {
  name: string
}
```

```typescript ['interface']
export interface Pet {
  name: string
}
```

:::

A `type` alias and an `interface` are consumed the same way. Both annotate a value the same:

```typescript
import type { Pet } from './src/gen/types/Pet'

const pet: Pet = { name: 'Fluffy' }
```

### optionalType

How optional properties are written in generated types.

- `'questionToken'` (default) writes `type?: string`. The property may be missing.
- `'undefined'` writes `type: string | undefined`. The property must exist but may be `undefined`.
- `'questionTokenAndUndefined'` writes `type?: string | undefined`. This is the strictest option: the property may be missing or explicitly set to `undefined`.

|          |                                                                |
| -------: | :------------------------------------------------------------- |
|    Type: | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` |
| Default: | `'questionToken'`                                              |

> [!TIP]
> Choose `'questionTokenAndUndefined'` when your project enables `"exactOptionalPropertyTypes": true` in `tsconfig.json`. It keeps generated types compatible with that setting.

::: code-group

```typescript ['questionToken' (default)]
export type Pet = {
  type?: string
}
```

```typescript ['undefined']
export type Pet = {
  type: string | undefined
}
```

```typescript ['questionTokenAndUndefined']
export type Pet = {
  type?: string | undefined
}
```

:::

Each value changes what an assignment may do with the optional property:

::: code-group

```typescript ['questionToken' (default)]
import type { Pet } from './src/gen/types/Pet'

const a: Pet = {} // ok, `type` may be missing
const b: Pet = { type: 'dog' } // ok
```

```typescript ['undefined']
import type { Pet } from './src/gen/types/Pet'

const a: Pet = { type: undefined } // ok, `type` must be present
const b: Pet = {} // error, `type` is required
```

```typescript ['questionTokenAndUndefined']
import type { Pet } from './src/gen/types/Pet'

const a: Pet = {} // ok, may be missing
const b: Pet = { type: undefined } // ok, may be explicitly undefined
```

:::

### arrayType

Syntax used for array types in generated code.

- `'array'` (default) uses the postfix `Type[]`, which is slightly shorter.
- `'generic'` uses `Array<Type>`, which reads better for complex element types such as `Array<{ id: number }>`.

|          |                        |
| -------: | :--------------------- |
|    Type: | `'array' \| 'generic'` |
| Default: | `'array'`              |

::: code-group

```typescript ['array' (default)]
export type Pet = {
  tags: string[]
}
```

```typescript ['generic']
export type Pet = {
  tags: Array<string>
}
```

:::

Both array styles are consumed the same way. `Pet['tags']` is iterable either way:

```typescript
import type { Pet } from './src/gen/types/Pet'

const pet: Pet = { tags: ['cute', 'small'] }
pet.tags.forEach((tag) => console.log(tag))
```

### include

Generates only the operations and schemas that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

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

Skips any operation or schema that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

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

For example, `override: [{ type: 'tag', pattern: 'user', options: { enum: { type: 'literal' } } }]` switches the `user` tag to literal enums while the rest of the spec keeps the plugin default.

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change, since anything you omit keeps its default behavior. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|          |                                              |
| -------: | :------------------------------------------- |
|    Type: | `Partial<ResolverTs> & ThisType<ResolverTs>` |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (for example stripping descriptions), use `macros` instead.

For example, `resolver: { resolveTypeName(name) { return \`Api${this.default(name, 'function')}\` } }` prefixes every generated type name with `Api`.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|          |                |
| -------: | :------------- |
|    Type: | `Array<Macro>` |

> [!TIP]
> Use `macros` to rewrite node properties before printing. For changing the names of generated symbols and files, use `resolver` instead.

Each entry names the macro and supplies one callback per node kind:

```typescript [A macros array]
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  macros: [
    {
      name: 'strip-descriptions',
      schema(node) {
        return { ...node, description: undefined }
      },
    },
    {
      name: 'prefix-operation-id',
      operation(node) {
        return { ...node, operationId: `api_${node.operationId}` }
      },
    },
  ],
})
```

### printer

Replaces the TypeScript node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler builds a TypeScript AST node for that type. Use `this.transform` to recurse into nested nodes, and `this.options` to read printer options. The [printer guide](/docs/5.x/guide/going-further/printers) covers the handler context and how overrides compose with macros.

|          |                              |
| -------: | :--------------------------- |
|    Type: | `{ nodes?: PrinterTsNodes }` |

```typescript [Map date schemas to the Date object]
import ts from 'typescript'
import { pluginTs } from '@kubb/plugin-ts'

pluginTs({
  printer: {
    nodes: {
      date() {
        return ts.factory.createTypeReferenceNode('Date', [])
      },
      integer() {
        return ts.factory.createKeywordTypeNode(ts.SyntaxKind.BigIntKeyword)
      },
    },
  },
})
```
