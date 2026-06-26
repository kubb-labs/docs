---
layout: doc
title: Kubb TypeScript Plugin
description: Generate TypeScript types and interfaces from OpenAPI schemas with
  full type safety end to end.
outline: 2
kind: plugin
id: plugin-ts
name: TypeScript
category: types
type: official
npmPackage: "@kubb/plugin-ts"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-ts
featured: true
icon:
  light: https://kubb.dev/feature/typescript.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - typescript
  - types
  - interfaces
  - codegen
  - openapi
dependencies: []
resources:
  documentation: https://kubb.dev/plugins/plugin-ts
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/typescript
---

# @kubb/plugin-ts

`@kubb/plugin-ts` turns your OpenAPI schemas into TypeScript types and interfaces. Most other Kubb plugins build on it. Clients, query hooks, mocks, and validators reuse the names it generates. That way every request, response, parameter, and enum is checked at compile time.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-ts@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-ts@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-ts@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-ts@beta
```

:::

## Options

### output

Where the generated `.ts` files are written and how they are exported.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `Output`                                       |
| Required: | `false`                                        |
|  Default: | `{ path: 'types', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files. It is resolved against the global `output.path` on `defineConfig`. To write everything to one file instead, set `output.mode: 'file'` and give `path` a file name with its extension, such as `'types.ts'`.

|           |           |
| --------: | :-------- |
|     Type: | `string`  |
| Required: | `true`    |
|  Default: | `'types'` |

> [!TIP]
> `output.path` sets where files go, `output.mode` sets how many. Use `'directory'` (the default) for one file per operation, optionally grouped into subdirectories with the `group` option. Use `'file'` to write everything into a single file.

#### output.mode

How the plugin consolidates its generated code into files.

- `'directory'` (default) writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file. The `output.path` must include the file extension (e.g. `'types.ts'`, `'models.py'`).

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

Text added to the top of every generated file. Use it for license headers, lint disables, or a `@ts-nocheck` directive. Pass a string for a fixed banner, or a function that builds one from each file's `RootNode` (the AST root with the path, schema, and operation context).

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

A static `banner: '/* eslint-disable */\n// @ts-nocheck'` lands at the top of each generated file:

```typescript
/* eslint-disable */
// @ts-nocheck
export type Pet = {
  id: number
  name: string
}
```

A function banner builds the text from the file's `RootNode`, such as `banner: (node) => \`// Source: ${node.filePath}\``.

#### output.footer

Text added to the bottom of every generated file. It works like `banner` but for closing comments, such as re-enabling a lint rule. Pass a string or a function that receives the file's `RootNode` and returns the text. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `string \| ((node: RootNode) => string)` |
| Required: | `false`                                  |

### group

Splits generated files into subfolders by the operation's tag or URL path. Each group gets its own directory under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`.

|           |         |
| --------: | :------ |
|     Type: | `Group` |
| Required: | `false` |

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

- `'tag'` uses the operation's first tag (`operation.getTags().at(0)?.name`).
- `'path'` uses the first segment of the operation's URL, such as `pet` for `/pet/{petId}`.

Operations with no tag go in a default group.

|           |                   |
| --------: | :---------------- |
|     Type: | `'tag' \| 'path'` |
| Required: | `true`            |

> [!NOTE]
> `Required: true*` is conditional. It only applies when the parent `group` option is used, and `group` itself stays optional.

#### group.name

Function that turns a group key (the operation's first tag) into a folder/identifier name.

The result is used as both the subdirectory name under `output.path` and as a suffix when naming aggregate files.

|           |                                     |
| --------: | :---------------------------------- |
|     Type: | `(context: GroupContext) => string` |
| Required: | `false`                             |
|  Default: | `(ctx) => \`${ctx.group}\``         |

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

|           |                                                                                       |
| --------: | :------------------------------------------------------------------------------------ |
|     Type: | `EnumOptions`                                                                         |
| Required: | `false`                                                                               |
|  Default: | `{ type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' }` |

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

|           |                                                                      |
| --------: | :------------------------------------------------------------------- |
|     Type: | `'asConst' \| 'enum' \| 'constEnum' \| 'literal' \| 'inlineLiteral'` |
| Required: | `false`                                                              |
|  Default: | `'asConst'`                                                          |

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

|           |                               |
| --------: | :---------------------------- |
|     Type: | `'camelCase' \| 'pascalCase'` |
| Required: | `false`                       |
|  Default: | `'camelCase'`                 |

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

The const object name (e.g. `petStatus`) is unaffected, so only the companion type alias is renamed. Set it to `''` to drop the suffix, which (with `constCasing: 'pascalCase'`) merges the const and type under one name.

|           |          |
| --------: | :------- |
|     Type: | `string` |
| Required: | `false`  |
|  Default: | `'Key'`  |

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

|           |                                                                                |
| --------: | :----------------------------------------------------------------------------- |
|     Type: | `'screamingSnakeCase' \| 'snakeCase' \| 'pascalCase' \| 'camelCase' \| 'none'` |
| Required: | `false`                                                                        |
|  Default: | `'none'`                                                                       |

| Value                  | Example key  |
| ---------------------- | ------------ |
| `'screamingSnakeCase'` | `ENUM_VALUE` |
| `'snakeCase'`          | `enum_value` |
| `'pascalCase'`         | `EnumValue`  |
| `'camelCase'`          | `enumValue`  |
| `'none'` (default)     | as-is        |

### dateType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#dateType). Use `adapterOas({ dateType })` instead.

### integerType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#integerType). Use `adapterOas({ integerType })` instead.

### syntaxType

Whether object schemas are emitted as `type` aliases or `interface` declarations.

`type` is the safer default for generated code. Type aliases are closed, intersections work cleanly, and unions are fine. Pick `interface` only when consumers need declaration merging, which is rare for generated code.

For more background, see [Type vs Interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use).

|           |                         |
| --------: | :---------------------- |
|     Type: | `'type' \| 'interface'` |
| Required: | `false`                 |
|  Default: | `'type'`                |

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

### unknownType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#unknownType). Use `adapterOas({ unknownType })` instead.

### emptySchemaType

|           |         |
| --------: | :------ |
| Required: | `false` |

> [!WARNING]
> Moved to [`adapterOas`](/adapters/adapter-oas#emptySchemaType). Use `adapterOas({ emptySchemaType })` instead.

### optionalType

How optional properties are written in generated types.

- `'questionToken'` (default) writes `type?: string`. The property may be missing.
- `'undefined'` writes `type: string | undefined`. The property must exist but may be `undefined`.
- `'questionTokenAndUndefined'` writes `type?: string | undefined`. This is the strictest option: the property may be missing or explicitly set to `undefined`.

|           |                                                                 |
| --------: | :-------------------------------------------------------------- |
|     Type: | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` |
| Required: | `false`                                                         |
|  Default: | `'questionToken'`                                               |

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

|           |                        |
| --------: | :--------------------- |
|     Type: | `'array' \| 'generic'` |
| Required: | `false`                |
|  Default: | `'array'`              |

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

### resolver

Changes how the plugin names generated files and symbols. Use it to add a prefix or suffix, or to swap the casing, without forking the plugin. Override only the methods you want to change. Anything you omit, or that returns `null` or `undefined`, falls back to the default. Inside a method, `this` is the full resolver, so you can call `this.default(name, 'function')` to reuse the built-in name.

|           |                                              |
| --------: | :------------------------------------------- |
|     Type: | `Partial<ResolverTs> & ThisType<ResolverTs>` |
| Required: | `false`                                      |

> [!TIP]
> Use `resolver` for naming and file-location tweaks. For changing the AST nodes themselves (e.g. stripping descriptions), use `macros` instead.

For example, `resolver: { resolveTypeName(name) { return \`Api${this.default(name, 'function')}\` } }` prefixes every generated type name with `Api`.

Each plugin ships with a default resolver:

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

### include

Generates only the operations and schemas that match at least one entry in the list. Everything else is skipped. Each entry filters by one of:

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

Pass `include: [{ type: 'tag', pattern: 'pet' }]` to keep only the `pet` tag. Stack entries to narrow further, such as `{ type: 'method', pattern: 'GET' }` with `{ type: 'path', pattern: /^\/pet/ }` for GET operations under `/pet`.

### exclude

Skips any operation or schema that matches at least one entry in the list. It is the opposite of `include`. Entries use the same `type` (`tag`, `operationId`, `path`, `method`, `contentType`, `schemaName`) and `pattern` (string or `RegExp`). When both are set, `exclude` wins.

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

Pass `exclude: [{ type: 'tag', pattern: 'store' }]` to drop the `store` tag, or stack `{ type: 'operationId', pattern: 'deletePet' }` with `{ type: 'method', pattern: 'DELETE' }` to skip one operation and every DELETE.

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

For example, `override: [{ type: 'tag', pattern: 'user', options: { enum: { type: 'literal' } } }]` switches the `user` tag to literal enums while the rest of the spec keeps the plugin default.

### macros

Rewrites AST nodes before they are printed to source. Use it to rename operation IDs, drop descriptions, or change schema metadata without forking the generator. Each [macro](/docs/5.x/concepts/macros) callback (such as `schema` or `operation`) receives the node and a context object. Return a new node to replace it, or `undefined` to leave it as is. Callbacks you omit keep their default behavior. Macros run in order, so a later one sees the output of an earlier one.

|           |                 |
| --------: | :-------------- |
|     Type: | `Array<Macro>`  |
| Required: | `false`         |

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

Replaces the TypeScript node handler for a specific schema type, such as `'integer'`, `'date'`, or `'string'`. Each handler builds a TypeScript AST node for that type.

Use `this.transform` to recurse into nested nodes, and `this.options` to read printer options.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `{ nodes?: PrinterTsNodes }` |
| Required: | `false`                      |

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

## readOnly and writeOnly

OpenAPI marks a field `readOnly` when the server owns it and `writeOnly` when the client sends it but never reads it back. `@kubb/plugin-ts` honors both at the operation boundary, where it already emits separate request and response types.

A `readOnly` field stays out of the request type, and a `writeOnly` field stays out of every response type. The field is removed with `Omit`, so a write-only field such as a password cannot reach a response type.

Take a `Pet` schema with a `readOnly` `id` and a `writeOnly` `password`. The request body and the `200` response both reference `Pet`, yet each keeps only the fields that belong to its direction:

```typescript
// id is server-owned, so the request never carries it
export type AddPetData = Omit<NonNullable<Pet>, 'id'>

// password is write-only, so the response never exposes it
export type AddPetStatus200 = Omit<NonNullable<Pet>, 'password'>
```

The standalone `Pet` type still carries every field, including its `readonly id`. Only the per-operation request and response types drop what does not belong to that direction. This needs no configuration and no helper types such as `Readable<T>` or `Writable<T>`.

> [!NOTE]
> Filtering applies to the properties declared directly on the request or response body schema. A read-only or write-only field nested deeper inside a referenced schema stays in place. Reach for a [macro](#macros) when you need to rewrite those.

## Dependencies

`@kubb/plugin-ts` has no plugin dependencies. It reads the OpenAPI spec through `@kubb/adapter-oas` and produces the type names every other plugin reuses, so add it whenever a client, query, mock, or validator plugin needs typed output.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
      exclude: [{ type: 'tag', pattern: 'store' }],
      group: { type: 'tag' },
      enum: { type: 'asConst' },
      optionalType: 'questionTokenAndUndefined',
    }),
  ],
})
```

:::

## See Also

- [TypeScript](https://www.typescriptlang.org/)
- [TypeScript Compiler API](https://github.com/microsoft/TypeScript/wiki/Using-the-Compiler-API)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-ts/CHANGELOG.md)
