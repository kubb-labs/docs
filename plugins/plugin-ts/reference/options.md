---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-ts.
outline: deep
---

# Options

Options for `pluginTs`, with type and default in the table.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'types' }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | — | Split output into per-tag or per-path folders |
| [`enum`](#enum) | `EnumOptions` | `{ type: 'asConst', … }` | How enums are generated and cased |
| [`syntaxType`](#syntaxtype) | `'type' \| 'interface'` | `'type'` | Emit object schemas as type aliases or interfaces |
| [`optionalType`](#optionaltype) | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` | `'questionToken'` | How optional properties are written |
| [`arrayType`](#arraytype) | `'array' \| 'generic'` | `'array'` | `Type[]` or `Array<Type>` |
| [`operationTypes`](#operationtypes) | `boolean` | `true` | Reference base component types instead of per-operation aliases |
| [`include`](#include) | `Array<Include>` | — | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | — | Skip operations that match |
| [`override`](#override) | `Array<Override>` | — | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverTs>` | — | Customize generated names and file paths |
| [`macros`](#macros) | `Array<Macro>` | — | Rewrite AST nodes before printing |
| [`printer`](#printer) | `{ nodes?: PrinterTsNodes }` | — | Replace the handler for a schema type |

### output

Where the generated `.ts` files are written and how they are exported.

#### output.path

Folder where the plugin writes its files (`string`, default `'types'`), resolved against the global `output.path` on `defineConfig`.

#### output.mode

How generated code is consolidated into files. Defaults to `'file'`.

- `'file'` writes everything into a single file, so `output.path` needs a file extension such as `'types.ts'`.
- `'directory'` writes one file per operation or schema under `output.path`.

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

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

### operationTypes

Whether to keep the per-operation alias layer or reference base component types directly. Defaults to `true`.

With `operationTypes: false`, a request body or response backed by a single `$ref` resolves to the referenced component (for example `Pet`) instead of the `AddPetData` or `AddPetStatus200` alias, and those aliases are no longer emitted. Inline, array, union, multiple-content-type, and `Omit`-based schemas keep their per-operation alias, since no single base type exists.

The option is carried by the plugin-ts resolver, so consumer plugins (the client plugins, React Query, Vue Query, SWR, Faker, MSW, Cypress) inherit the inlining and import each base component from its own file.

::: code-group

```typescript ['true' (default)]
import type { AddPetData, AddPetStatus200 } from '../models/AddPet'

export async function addPet(data?: AddPetData) {
  const res = await request<AddPetData>({ /* ... */ })
  return res.data
}
```

```typescript ['false']
import type { Pet } from '../models/Pet'

export async function addPet(data?: Pet) {
  const res = await request<Pet>({ /* ... */ })
  return res.data
}
```

:::

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes how the plugin names generated files and symbols. Pass a partial patch. Override only the members you want, and anything you omit keeps `resolverTs`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the `this` context and how a patch layers over the default.

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

<!--@include: ../../../snippets/how-to/macros-option.md-->

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
