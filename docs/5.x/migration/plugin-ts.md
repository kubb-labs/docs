---
title: 'Migration: @kubb/plugin-ts'
description: Configuration and generated-output changes for @kubb/plugin-ts when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-ts`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). See the full option reference in [`@kubb/plugin-ts`](/plugins/plugin-ts/).

## Removed: `mapper`

```typescript [v4 kubb.config.ts]
pluginTs({ mapper: { status: 'string' } })
```

Use [`printer.nodes`](/plugins/plugin-ts/reference/options#printer) to override a schema-type renderer, or [`macros`](/plugins/plugin-ts/reference/options#macros) to rewrite AST nodes before printing.

## Removed: `paramsCasing`

```typescript [v4 kubb.config.ts]
pluginTs({ paramsCasing: 'camelcase' })
```

Parameter properties inside the generated `PathParams`, `QueryParams`, `HeaderParams`, and `RequestConfig` types are now always camelCase. In v4 they defaulted to the original spec names, and `paramsCasing: 'camelcase'` opted into the new behavior. v5 makes camelCase the only option, so drop the setting.

```typescript [Generated output]
// OpenAPI spec uses: pet_id, X-Api-Key
export type GetPetPathParams = { petId: string } // was { pet_id: string }
export type GetPetHeaderParams = { xApiKey?: string } // was { 'X-Api-Key'?: string }
```

## Changed: `RequestConfig` groups request input

The generated `*RequestConfig` type now groups every request input under `{ path, query, body, headers }` so the client, query, and Cypress plugins all share one call shape. Each key holds the matching `*PathParams`, `*QueryParams`, `*Body`, or `*HeaderParams` type, or `never` when the operation has none. The `path`, `query`, and `headers` keys are required when the operation has a required parameter in that group, and the unused keys are typed `never` so passing them is a compile error.

::: code-group

```typescript [Generated output]
export type GetPetRequestConfig = {
  path: { petId: string } // required: the operation has a required path param
  query?: GetPetQueryParams
  body?: never
  headers?: never
  url: '/pet/{petId}'
}

export type AddPetRequestConfig = {
  path?: never
  query?: never
  body: AddPetBody
  headers?: never
  url: '/pet'
}
```

:::

The grouped object is what every generated client function, hook, and Cypress helper takes as its first argument, typed `Omit<XxxRequestConfig, 'url'>`. See the [client plugin removal note](/docs/5.x/migration/plugin-client), [plugin-react-query](/docs/5.x/migration/plugin-react-query), and [plugin-cypress](/docs/5.x/migration/plugin-cypress) pages for the call-site changes.

## Renamed: `transformers.name`

[`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the full guide.

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, and `contentType` moved to [`adapterOas`](/adapters/adapter-oas/). See [Migration: @kubb/adapter-oas](/docs/5.x/migration/adapter-oas).

## Changed: `enum` options grouped under one object

The loose `enumType`, `enumTypeSuffix`, and `enumKeyCasing` options now live inside one `enum` object. A new `enum.constCasing` sets the casing of the generated const. The old `enumType: 'asPascalConst'` is gone. Use `constCasing: 'pascalCase'` instead.

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
  input: './petstore.yaml',
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
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petstore.yaml',
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
> Set `constCasing: 'pascalCase'` with `typeSuffix: ''` to emit a const and a type that share the schema's exact name. Most hand-written codebases use this convention, so existing annotations and value references keep working.
>
> ```typescript [v5 kubb.config.ts]
> pluginTs({ enum: { type: 'asConst', constCasing: 'pascalCase', typeSuffix: '' } })
> ```
>
> ```typescript [Generated output]
> export const VehicleType = {
>   Sedan: 'Sedan',
>   SUV: 'SUV',
> } as const
>
> export type VehicleType = (typeof VehicleType)[keyof typeof VehicleType]
> ```

## Generated output

### Enums: object literal instead of `enum`

v5 emits a `const`-asserted object plus a `*Key` type union. This drops the runtime cost of a TypeScript `enum` and stays tree-shakeable.

```diff [Generated output]
-export enum ParamsStatusEnum {
-  placed = 'placed',
-  approved = 'approved',
-  delivered = 'delivered',
-}
+export const orderParamsStatusEnum = {
+  placed: 'placed',
+  approved: 'approved',
+  delivered: 'delivered',
+} as const
+export type OrderParamsStatusEnumKey = (typeof orderParamsStatusEnum)[keyof typeof orderParamsStatusEnum]

-status: ParamsStatusEnum
+status: OrderParamsStatusEnumKey
```

Enum names are now operation-scoped (`orderParamsStatusEnum`, `customerParamsStatusEnum`) instead of suffix-deduplicated (`ParamsStatusEnum`, `ParamsStatusEnum2`), so the numeric collisions are gone. Configure [`enum`](/plugins/plugin-ts/) on `pluginTs` when you want `enum`, `constEnum`, `literal`, or a different const and type casing.

### `int64` maps to `bigint` by default

`adapterOas` defaults `integerType` to `'bigint'`, so OpenAPI fields with `format: int64` generate `bigint` instead of `number`.

```diff [Diff]
- petId?: number
+ petId?: bigint
```

Set `integerType: 'number'` on `adapterOas` to restore the previous output.

### Open string unions use `(string & {})`

v5 writes the known TypeScript trick to keep IntelliSense suggestions.

```diff [Diff]
- status?: 'accepted' | string
+ status?: 'accepted' | (string & {})
```

### JSDoc

The format suffix drops off the `@type` tag (`@type integer | undefined, int64` becomes `@type integer | undefined`), since the schema already documents the format. v5 emits `@example` from the OpenAPI `example` field, and object schemas now carry an `@type object` tag.

### Discriminated unions are factored

Fields shared by every variant of a `oneOf`/`anyOf` move into a common object:

```diff [Diff]
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
