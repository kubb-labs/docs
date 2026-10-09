---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-ts.
outline: deep
---

# Options

Configuration options for @kubb/plugin-ts.

## Options overview

Select an option to see its type, default, and examples. Nested settings link to their own section or the parent option.

| Option | Purpose |
| --- | --- |
| [`output`](#output) | Where the generated files are written and exported. |
| ↳ [`output.path`](#output-path) | Choose the output folder or file. |
| ↳ [`output.mode`](#output-mode) | Write a single file or a directory of files. |
| ↳ [`output.barrel`](#output-barrel) | Configure barrel exports. |
| ↳ [`output.barrel.type`](#output-barrel) | Use named exports or wildcard exports. |
| ↳ [`output.barrel.nested`](#output-barrel) | Choose whether barrels reference subdirectory barrels. |
| ↳ [`output.banner`](#output-banner) | Add content before generated code. |
| ↳ [`output.footer`](#output-footer) | Add content after generated code. |
| [`group`](#group) | Split output into per-tag or per-path folders. |
| ↳ [`group.type`](#group-type) | Group operations by tag or URL path. |
| ↳ [`group.name`](#group-name) | Customize output group names. |
| [`enum`](#enum) | How enums are generated and cased. |
| ↳ [`enum.type`](#enum-type) | Choose how enums are generated. |
| ↳ [`enum.constCasing`](#enum-constcasing) | Set the casing of enum constants. |
| ↳ [`enum.typeSuffix`](#enum-typesuffix) | Set the companion type suffix. |
| ↳ [`enum.keyCasing`](#enum-keycasing) | Set the casing of enum keys. |
| [`syntaxType`](#syntaxtype) | Emit object schemas as type aliases or interfaces. |
| [`optionalType`](#optionaltype) | How optional properties are written. |
| [`arrayType`](#arraytype) | `Type[]` or `Array<Type>`. |
| [`include`](#include) | Keep only operations that match. |
| [`exclude`](#exclude) | Skip operations that match. |
| [`override`](#override) | Apply different options per pattern. |
| [`resolver`](#resolver) | Customize generated names and file paths. |
| [`macros`](#macros) | Rewrite AST nodes before printing. |
| [`printer`](#printer) | Replace the handler for a schema type. |
| ↳ [`printer.nodes`](#printer) | Customize handlers for schema node types. |

## Option details

### output

Where the generated `.ts` files are written and how they are exported.

| | |
| --- | --- |
| Type | `Output` |
| Required | `false` |
| Default | `{ path: 'types', barrel: { type: 'named' } }` |

#### output.path

Folder where the plugin writes its files (`string`, default `'types'`), resolved against the global `output.path` on `defineConfig`.

#### output.mode

How generated code is consolidated into files.

- `'file'` writes everything into a single file, so `output.path` needs a file extension such as `'types.ts'`.
- `'directory'` writes one file per operation or schema under `output.path`.

Leave it unset and Kubb reads `output.path`: a name with an extension means one file, anything else a directory.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

Split output into per-tag or per-path folders.

| | |
| --- | --- |
| Type | `Group` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.name

Turns a group key into a folder or identifier name, used as the subdirectory name and as a suffix on aggregate files. Type `(context: { group: string }) => string`, default `({ group }) => camelCase(group)`, which for `type: 'path'` groups uses the first URL segment as-is instead of camelCasing.

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

| | |
| --- | --- |
| Type | `EnumOptions` |
| Required | `false` |
| Default | `{ type: 'asConst', … }` |

#### enum.type

Representation of each enum. Defaults to `'asConst'`.

- `'asConst'` emits an `as const` object plus a key/value type. Tree-shakeable, with no runtime.
- `'enum'` emits a TypeScript `enum` with JavaScript runtime code.
- `'constEnum'` emits a `const enum`, inlined at compile time and incompatible with `--isolatedModules`.
- `'literal'` emits a union type with no runtime value.
- `'inlineLiteral'` inlines the union at each usage site instead of giving it a name.

::code-group

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

::

#### enum.constCasing

Casing of the generated const variable when `type` is `'asConst'`. Defaults to `'camelCase'`.

- `'camelCase'` names the const `petStatus`.
- `'pascalCase'` names the const `PetStatus`, matching the schema name.

::code-group

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

::

#### enum.typeSuffix

Suffix on the type alias generated when `type` is `'asConst'` (`string`, default `'Key'`), applied only to the companion type alias, not the const object name. Set it to `''` to drop the suffix, which with `constCasing: 'pascalCase'` merges the const and type under one name.

::code-group

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

::

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

Whether object schemas are emitted as `type` aliases or `interface` declarations, with `type` as the safer default. Pick `interface` only when consumers need declaration merging, which is rare for generated code and covered in [Type vs Interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use).

| | |
| --- | --- |
| Type | `'type' \| 'interface'` |
| Required | `false` |
| Default | `'type'` |

::code-group

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

::

### optionalType

How optional properties are written. Defaults to `'questionToken'`.

| | |
| --- | --- |
| Type | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` |
| Required | `false` |
| Default | `'questionToken'` |

- `'questionToken'` writes `type?: string`, so the property may be missing.
- `'undefined'` writes `type: string | undefined`, so it must exist but may be `undefined`.
- `'questionTokenAndUndefined'` writes `type?: string | undefined`, the strictest form. Use it with `"exactOptionalPropertyTypes": true`.

::code-group

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

::

### arrayType

Syntax for array types. Defaults to `'array'`.

| | |
| --- | --- |
| Type | `'array' \| 'generic'` |
| Required | `false` |
| Default | `'array'` |

- `'array'` uses the postfix `Type[]`.
- `'generic'` uses `Array<Type>`, which reads better for complex elements like `Array<{ id: number }>`.

::code-group

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

::

### include

Keep only operations that match.

| | |
| --- | --- |
| Type | `Array<Include>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

Skip operations that match.

| | |
| --- | --- |
| Type | `Array<Exclude>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

Apply different options per pattern.

| | |
| --- | --- |
| Type | `Array<Override>` |
| Required | `false` |
| Default | `[]` |

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Overrides generated file and symbol names. Omitted members keep the plugin's resolver defaults. See [Override a resolver](/docs/5.x/how-to/resolvers) for the `this` context and how a patch layers over the default.

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverTs>` |
| Required | `false` |

> [!TIP]
> Inside a method `this` is the full resolver, so `this.default.name(name)` reuses the built-in casing.

```typescript [Partial override]
type ResolverTsPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  param?: {
    name?(node: OperationNode, param: ParameterNode): string    // → 'DeletePetPathPetId'
    path?(node: OperationNode, param: ParameterNode): string     // → 'GetPetByIdPath'
    query?(node: OperationNode, param: ParameterNode): string    // → 'FindPetsByStatusQuery'
    headers?(node: OperationNode, param: ParameterNode): string  // → 'DeletePetHeaders'
  }
  response?: {
    status?(node: OperationNode, statusCode: StatusCode): string // → 'ListPetsStatus200'
    options?(node: OperationNode): string                        // → 'ListPetsOptions'
    responses?(node: OperationNode): string                      // → 'ListPetsResponses'
    response?(node: OperationNode): string                       // → 'ListPetsResponse'
    body?(node: OperationNode): string                           // → 'CreatePetBody'
  }
  enum?: {
    keyName?(node: { name?: string | null }, enumTypeSuffix?: string): string // → 'PetStatusKey'
  }
}
```

### macros

Rewrite AST nodes before printing.

| | |
| --- | --- |
| Type | `Array<Macro>` |
| Required | `false` |

<!--@include: ../../../snippets/how-to/macros-option.md-->

### printer

Replaces the node handler for a schema type such as `'integer'` or `'date'` with one that builds its TypeScript AST node. Use `this.transform` to recurse into nested nodes and `this.options` to read printer options. The [printer guide](/docs/5.x/how-to/printers) covers the handler context and how overrides compose with macros.

| | |
| --- | --- |
| Type | `{ nodes?: PrinterTsNodes }` |
| Required | `false` |

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
