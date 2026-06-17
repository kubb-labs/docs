---
title: 'Migration: @kubb/plugin-ts'
description: Configuration and generated-output changes for @kubb/plugin-ts when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-ts`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-ts`](/plugins/plugin-ts).

## Removed: `mapper`

```typescript [v4 kubb.config.ts]
pluginTs({ mapper: { status: 'string' } })
```

Use [`printer.nodes`](/plugins/plugin-ts#printer) to override specific schema-type renderers, or [`macros`](/plugins/plugin-ts#macros) to rewrite AST nodes before printing.

## Renamed: `transformers.name`

[`resolver.resolveTypeName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, and `contentType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas).

## Changed: `enum` options grouped under one object

The loose `enumType`, `enumTypeSuffix`, and `enumKeyCasing` options now live inside one `enum` object, and a new `enum.constCasing` sets the casing of the generated const. The old `enumType: 'asPascalConst'` is gone, so reach for `constCasing: 'pascalCase'` instead.

| v4 (old)                              | v5 (new)                                               |
| ------------------------------------- | ------------------------------------------------------ |
| `enumType: 'asConst'`                 | `enum: { type: 'asConst' }`                            |
| `enumType: 'asPascalConst'`           | `enum: { type: 'asConst', constCasing: 'pascalCase' }` |
| `enumTypeSuffix: 'Value'`             | `enum: { typeSuffix: 'Value' }`                        |
| `enumKeyCasing: 'screamingSnakeCase'` | `enum: { keyCasing: 'screamingSnakeCase' }`            |

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enumType: 'asConst',
      enumTypeSuffix: 'Key',
      enumKeyCasing: 'none',
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      enum: { type: 'asConst', constCasing: 'camelCase', typeSuffix: 'Key', keyCasing: 'none' },
    }),
  ],
})
```

:::

> [!TIP]
> Set `constCasing: 'pascalCase'` together with `typeSuffix: ''` to emit a const and a type that share the schema's exact name. This is the convention most hand-written codebases use, so migrating an existing project keeps every annotation and value reference working.
>
> ```typescript
> pluginTs({ enum: { type: 'asConst', constCasing: 'pascalCase', typeSuffix: '' } })
> ```
>
> ```typescript
> export const VehicleType = {
>   Sedan: 'Sedan',
>   SUV: 'SUV',
> } as const
>
> export type VehicleType = (typeof VehicleType)[keyof typeof VehicleType]
> ```

## Generated output

### Enums: object literal instead of `enum`

v5 emits a `const`-asserted object plus a `*Key` type union. This drops the runtime cost of a TypeScript `enum` and stays tree-shakable.

```typescript
export enum ParamsStatusEnum { // [!code --]
export enum orderParamsStatusEnum { // [!code ++]
  placed = 'placed',
  approved = 'approved',
  delivered = 'delivered',
}

status: ParamsStatusEnum // [!code --]
status: OrderParamsStatusEnumKey // [!code ++]
```

- Enum names are now operation-scoped (`orderParamsStatusEnum`, `customerParamsStatusEnum`, …) instead of suffix-deduplicated (`ParamsStatusEnum`, `ParamsStatusEnum2`, …), so the numeric collisions are gone.
- Configure [`enum`](/plugins/plugin-ts) on `pluginTs` when you want `enum`, `constEnum`, `literal`, or a different const and type casing.

### `int64` maps to `bigint` by default

`adapterOas` now defaults `integerType` to `'bigint'`, so OpenAPI fields with `format: int64` generate `bigint` instead of `number`.

```diff
- petId?: number
+ petId?: bigint
```

Set `integerType: 'number'` on `adapterOas` to restore the previous output.

### Open string unions use `(string & {})`

To keep IntelliSense suggestions, v5 writes the known TypeScript trick.

```diff
- status?: 'accepted' | string
+ status?: 'accepted' | (string & {})
```

### JSDoc

- `@type integer | undefined, int64` → `@type integer | undefined`. The format suffix is removed, since the schema documents the format rather than the type comment.
- `@example` is emitted from the OpenAPI `example` field.
- Object schemas now carry an `@type object` JSDoc tag.

### Discriminated unions are factored

Fields shared by every variant of a `oneOf`/`anyOf` move into a common object:

```diff
- export type Pet =
-   | { id?: number; name: string; status?: StatusEnum; ... }
-   | { id?: number; name: string; status?: StatusEnum; ... }
+ export type Pet = ({ ... } | { ... }) & {
+   id?: number
+   name: string
+   status?: PetStatusEnumKey
+   ...
+ }
```
