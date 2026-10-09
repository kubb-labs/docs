---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-ts.
outline: deep
---

# Options

Pass these options to `pluginTs()`. Shared options link to [Shared plugin options](/docs/5.x/reference/plugin-options), which documents their behavior once.

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`output`](/docs/5.x/reference/plugin-options#output) | Where the generated files are written and exported. | `{ path: 'types', barrel: { type: 'named' } }` |
| ↳ [`output.path`](/docs/5.x/reference/plugin-options#output-path) | Choose the output folder or file. | `'types'` |
| ↳ [`output.mode`](/docs/5.x/reference/plugin-options#output-mode) | Write a single file or a directory of files. | Inferred from `output.path` |
| ↳ [`output.barrel`](/docs/5.x/reference/plugin-options#output-barrel) | Configure barrel exports. | `{ type: 'named' }` |
| ↳ [`output.banner`](/docs/5.x/reference/plugin-options#output-banner) | Add content before generated code. | None |
| ↳ [`output.footer`](/docs/5.x/reference/plugin-options#output-footer) | Add content after generated code. | None |
| [`group`](/docs/5.x/reference/plugin-options#group) | Split output into per-tag or per-path folders. | None |
| ↳ [`group.type`](/docs/5.x/reference/plugin-options#group-type) | Group operations by tag or URL path. | Required with `group` |
| ↳ [`group.name`](/docs/5.x/reference/plugin-options#group-name) | Customize output group names. | camelCased tag or raw path segment |
| [`enum`](#enum) | How enums are generated and cased. | `{ type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' }` |
| ↳ [`enum.type`](#enum-type) | Choose how enums are generated. | `'asConst'` |
| ↳ [`enum.constCasing`](#enum-constcasing) | Set the casing of enum constants. | `'camelCase'` |
| ↳ [`enum.typeSuffix`](#enum-typesuffix) | Set the companion type suffix. | `'Key'` |
| ↳ [`enum.keyCasing`](#enum-keycasing) | Set the casing of enum keys. | `'none'` |
| [`syntaxType`](#syntaxtype) | Emit object schemas as type aliases or interfaces. | `'type'` |
| [`optionalType`](#optionaltype) | How optional properties are written. | `'questionToken'` |
| [`arrayType`](#arraytype) | `Type[]` or `Array<Type>`. | `'array'` |
| [`include`](/docs/5.x/reference/plugin-options#include) | Keep only operations and schemas that match. | None |
| [`exclude`](/docs/5.x/reference/plugin-options#exclude) | Skip operations and schemas that match. | `[]` |
| [`override`](/docs/5.x/reference/plugin-options#override) | Apply different options per pattern. | `[]` |
| [`resolver`](#resolver) | Customize generated names and file paths. | `resolverTs` |
| [`macros`](/docs/5.x/reference/plugin-options#macros) | Rewrite AST nodes before printing. | `[]` |
| [`printer`](#printer) | Replace the handler for a schema type. | None |
| ↳ [`printer.nodes`](#printer) | Customize handlers for schema node types. | None |

## Option details

### enum

How OpenAPI enums are represented in the generated TypeScript, and how their names are cased.

| | |
| --- | --- |
| Type | `{ type?, constCasing?, typeSuffix?, keyCasing? }` |
| Required | `false` |
| Default | `{ type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' }` |

`constCasing` and `typeSuffix` apply only to `type: 'asConst'`. `keyCasing` applies to `'asConst'`, `'enum'` and `'constEnum'`, since the literal modes emit values only.

#### enum.type

Representation of each enum.

| | |
| --- | --- |
| Type | `'asConst' \| 'enum' \| 'constEnum' \| 'literal' \| 'inlineLiteral'` |
| Required | `false` |
| Default | `'asConst'` |

::field-group

:::field{name="'asConst'"}
Default value. Emits an `as const` object plus a key/value type. Tree-shakeable, with no runtime.
:::

:::field{name="'enum'"}
Emits a TypeScript `enum` with JavaScript runtime code.
:::

:::field{name="'constEnum'"}
Emits a `const enum`, inlined at compile time and incompatible with `--isolatedModules`.
:::

:::field{name="'literal'"}
Emits a named union type with no runtime value.
:::

:::field{name="'inlineLiteral'"}
Emits the same union as `'literal'` but inlines it at each usage site instead of naming it.
:::

::

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

::

#### enum.constCasing

Casing of the generated const object when `type` is `'asConst'`.

| | |
| --- | --- |
| Type | `'camelCase' \| 'pascalCase'` |
| Required | `false` |
| Default | `'camelCase'` |

::field-group

:::field{name="'camelCase'"}
Default value. Names the const `petStatus`.
:::

:::field{name="'pascalCase'"}
Names the const `PetStatus`, matching the schema name.
:::

::

#### enum.typeSuffix

Suffix on the companion type alias when `type` is `'asConst'`. It never changes the const object name. Set it to `''` to drop the suffix, which with `constCasing: 'pascalCase'` merges the const and the type under one name, `PetStatus`.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `'Key'` |

```typescript [typeSuffix: 'Value']
export type PetStatusValue = (typeof petStatus)[keyof typeof petStatus]
```

#### enum.keyCasing

Casing applied to enum key names.

| | |
| --- | --- |
| Type | `'none' \| 'camelCase' \| 'pascalCase' \| 'snakeCase' \| 'screamingSnakeCase'` |
| Required | `false` |
| Default | `'none'` |

::field-group

:::field{name="'none'"}
Default value. Keeps the raw enum value from the spec as the key.
:::

:::field{name="'camelCase'"}
Formats keys as `enumValue`.
:::

:::field{name="'pascalCase'"}
Formats keys as `EnumValue`.
:::

:::field{name="'snakeCase'"}
Formats keys as `enum_value`.
:::

:::field{name="'screamingSnakeCase'"}
Formats keys as `ENUM_VALUE`.
:::

::

### syntaxType

How object schemas are declared.

| | |
| --- | --- |
| Type | `'type' \| 'interface'` |
| Required | `false` |
| Default | `'type'` |

::field-group

:::field{name="'type'"}
Default value. Generates type aliases, `export type Pet = { name: string }`.
:::

:::field{name="'interface'"}
Generates interface declarations, `export interface Pet { name: string }`. Use it when consumers need declaration merging. See [Type vs Interface](https://www.totaltypescript.com/type-vs-interface-which-should-you-use).
:::

::

### optionalType

How optional properties are written.

| | |
| --- | --- |
| Type | `'questionToken' \| 'undefined' \| 'questionTokenAndUndefined'` |
| Required | `false` |
| Default | `'questionToken'` |

::field-group

:::field{name="'questionToken'"}
Default value. Writes `type?: string`, so the property may be missing.
:::

:::field{name="'undefined'"}
Writes `type: string | undefined`, so it must exist but may be `undefined`.
:::

:::field{name="'questionTokenAndUndefined'"}
Writes `type?: string | undefined`, the strictest form. Use it with `"exactOptionalPropertyTypes": true`.
:::

::

### arrayType

Syntax for array types.

| | |
| --- | --- |
| Type | `'array' \| 'generic'` |
| Required | `false` |
| Default | `'array'` |

::field-group

:::field{name="'array'"}
Default value. Uses the postfix `tags: string[]`.
:::

:::field{name="'generic'"}
Uses `tags: Array<string>`, which reads better for complex elements like `Array<{ id: number }>`.
:::

::

### resolver

Overrides generated file and symbol names. Omitted members keep `resolverTs`. The shared members (`name`, `file`, `imports`) and the `this` context are described under [`resolver`](/docs/5.x/reference/plugin-options#resolver).

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverTs>` |
| Required | `false` |

::code-collapse{name="ResolverTs patch members"}

```typescript [Partial override]
type ResolverTsPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  imports?(options: ResolveImportsOptions): Array<ImportNode>
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

::

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
