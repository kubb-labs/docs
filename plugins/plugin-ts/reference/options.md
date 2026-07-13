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

#### output.path

Folder where the plugin writes its files (`string`, default `'types'`), resolved against the global `output.path` on `defineConfig`.

#### output.mode

How generated code is consolidated into files. Defaults to `'directory'`.

- `'directory'` writes one file per operation or schema under `output.path`.
- `'file'` writes everything into a single file, so `output.path` needs a file extension such as `'types.ts'`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

How the generated `index.ts` (barrel) re-exports the plugin's output. Defaults to `{ type: 'named' }`.

#### output.banner

Text added to the top of every generated file, such as a license header or `@ts-nocheck` directive. Pass a string, or a function `(meta: BannerMeta) => string` that receives the document info (`title`, `description`, `version`, `baseURL`) and per-file context (`filePath`, `baseName`, `isBarrel`, `isAggregation`), so a directive can skip barrel files.

#### output.footer

Text added to the bottom of every generated file (`string` or `(meta: BannerMeta) => string`), like `banner` but for closing comments. Pair `banner: '/* eslint-disable */'` with `footer: '/* eslint-enable */'` to scope a lint disable to the generated file.

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'`.

> [!IMPORTANT]
> Combining `group` with `output.mode: 'file'` stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### group.type

Property used to assign each operation to a group (`'tag' | 'path'`), required whenever `group` is set. An operation with no tag goes in the `default` group.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first URL segment, such as `pet` for `/pet/{petId}`.

#### group.name

Turns a group key into a folder or identifier name, used as the subdirectory name and as a suffix on aggregate files. Type `(context: { group: string }) => string`, default `({ group }) => camelCase(group)`, which for `type: 'path'` groups uses the first URL segment as-is instead of camelCasing.

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

#### enum.type

Representation of each enum. Defaults to `'asConst'`.

- `'asConst'` emits an `as const` object plus a key/value type. Tree-shakeable, with no runtime.
- `'enum'` emits a TypeScript `enum` with JavaScript runtime code.
- `'constEnum'` emits a `const enum`, inlined at compile time and incompatible with `--isolatedModules`.
- `'literal'` emits a union type with no runtime value.
- `'inlineLiteral'` inlines the union at each usage site instead of giving it a name.

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

#### enum.constCasing

Casing of the generated const variable when `type` is `'asConst'`. Defaults to `'camelCase'`.

- `'camelCase'` names the const `petStatus`.
- `'pascalCase'` names the const `PetStatus`, matching the schema name.

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

#### enum.typeSuffix

Suffix on the type alias generated when `type` is `'asConst'` (`string`, default `'Key'`). The const object name is unaffected, so only the companion type alias is renamed. Set it to `''` to drop the suffix, which with `constCasing: 'pascalCase'` merges the const and type under one name.

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

#### enum.keyCasing

Casing applied to enum key names, `'none'` by default (the raw value from the spec).

| Value                  | Example key  |
| ---------------------- | ------------ |
| `'screamingSnakeCase'` | `ENUM_VALUE` |
| `'snakeCase'`          | `enum_value` |
| `'pascalCase'`         | `EnumValue`  |
| `'camelCase'`          | `enumValue`  |
| `'none'` (default)     | as-is        |

### syntaxType

Whether object schemas are emitted as `type` aliases or `interface` declarations. `type` is the safer default. Pick `interface` only when consumers need declaration merging, which is rare for generated code and covered in [Type vs Interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use).

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

### optionalType

How optional properties are written. Defaults to `'questionToken'`.

- `'questionToken'` writes `type?: string`, so the property may be missing.
- `'undefined'` writes `type: string | undefined`, so it must exist but may be `undefined`.
- `'questionTokenAndUndefined'` writes `type?: string | undefined`, the strictest form. Use it with `"exactOptionalPropertyTypes": true`.

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

### arrayType

Syntax for array types. Defaults to `'array'`.

- `'array'` uses the postfix `Type[]`.
- `'generic'` uses `Array<Type>`, which reads better for complex elements like `Array<{ id: number }>`.

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

### include

Generates only the operations and schemas that match at least one entry, and skips the rest. Each entry filters by `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`, with a `pattern` that is a string (exact) or a `RegExp` (fuzzy).

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```

### exclude

Skips any operation or schema that matches at least one entry, the opposite of `include`. Entries use the same `type` and `pattern` fields as `include`, and when both options match an item, `exclude` wins.

### override

Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include`, plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. The first matching entry merges onto the plugin defaults, and later entries do not stack.

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```

### resolver

Changes how the plugin names generated files and symbols without forking the plugin. Override only the methods you want to change, and the rest keep their defaults. Inside a method, `this` is the full resolver, so `this.default.name(name)` reuses the built-in name. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for how a patch layers over the default.

### macros

Rewrites AST nodes before they are printed, without forking the generator. Each [macro](/docs/5.x/guide/going-further/macros) callback (such as `schema` or `operation`) receives the node and a context object, and returns a replacement or `undefined` to leave it as is. Omitted callbacks keep their defaults, and macros run in order.

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

Replaces the node handler for a schema type such as `'integer'` or `'date'` with one that builds its TypeScript AST node. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/guide/going-further/printers) covers the handler context and how overrides compose with macros.

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
