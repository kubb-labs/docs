---
title: 'Migration: @kubb/plugin-zod'
description: Configuration and generated-output changes for @kubb/plugin-zod when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-zod`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-zod`](/plugins/plugin-zod).

## Zod v3 no longer supported

The `version` option (`'3' | '4'`) is removed. v5 always generates [Zod v4](https://zod.dev) schemas.

Upgrade your `zod` dependency:

::: code-group

```shell [bun]
bun add zod@^4
```

```shell [pnpm]
pnpm add zod@^4
```

```shell [npm]
npm install zod@^4
```

```shell [yarn]
yarn add zod@^4
```

:::

## Removed: `mapper`

Use [`macros`](/plugins/plugin-zod#macros) or [`printer`](/plugins/plugin-zod#printer) instead.

## Renamed: `transformers.name`

[`resolver.resolveSchemaName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas).

## New: `mini`

Generate the functional syntax of [Zod Mini](https://zod.dev/packages/mini), which tree-shakes better. When `mini: true`, `importPath` defaults to `'zod/mini'`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginZod({ mini: true })],
})
```

## Changed: inferred type names end with `Type`

With `inferred: true`, the `z.infer<typeof schema>` alias now carries a `SchemaType` suffix. `petSchema` exports `PetSchemaType` instead of `PetSchema`.

In v4 the schema value and its inferred type differed only by casing (`petSchema` and `PetSchema`). An all-uppercase name such as `SUV`, `URL`, or `API` produced the same identifier for both, so the barrel re-exported it twice and failed to compile with `TS2300: Duplicate identifier`. The `Type` suffix keeps the value and type apart no matter the casing.

```typescript [zod/petSchema.ts]
export const petSchema = z.object({
  name: z.string(),
  status: z.enum(['available', 'pending', 'sold']).optional(),
})

export type PetSchemaType = z.infer<typeof petSchema> // [!code ++]
export type PetSchema = z.infer<typeof petSchema> // [!code --]
```

Update any imports that referenced the old name:

```typescript
import type { PetSchemaType } from './gen/zod/petSchema.ts' // [!code ++]
import type { PetSchema } from './gen/zod/petSchema.ts' // [!code --]
```

## Generated output

### Chained syntax instead of functional wrappers

v5 prefers the chained Zod 4 syntax. `.optional()` always sits at the end of the chain, right before `.describe()`.

```typescript
id: z.optional(z.int()), // [!code --]
shipDate: z.optional(z.iso.datetime()), // [!code --]
status: z.optional(z.enum(['placed', 'approved']).describe('Order Status')), // [!code --]
id: z.int().optional(), // [!code ++]
shipDate: z.iso.datetime().optional(), // [!code ++]
status: z.enum(['placed', 'approved']).optional().describe('Order Status'), // [!code ++]
```

The functional form (`z.optional(...)`) is now reserved for `mini: true` output, which lives in its own configured `output.path`.

### Self-referencing getters only for true cycles

v4 wrapped almost every nested ref in a getter. v5 only does so when the schema is truly circular, meaning it references itself or its parent.

```diff
- get category() {
-   return categorySchema.optional()
- },
- get tags() {
-   return z.array(tagSchema).optional()
- },
+ category: categorySchema.optional(),
+ tags: z.array(tagSchema).optional(),
  get parent() {
    return z.array(petSchema).optional()
  },
```
