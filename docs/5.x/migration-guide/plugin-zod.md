---
title: 'Migration: @kubb/plugin-zod'
description: Configuration changes for @kubb/plugin-zod when migrating from Kubb v4 to v5.
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

`transformers.name` is replaced by [`resolver.resolveSchemaName`](/docs/5.x/migration-guide#transformersname-resolver).

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas).

## New: `mini`

Generate [Zod Mini](https://zod.dev/packages/mini)'s functional syntax for better tree-shaking. When `mini: true`, `importPath` defaults to `'zod/mini'`.

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

Before, the schema value and its inferred type differed only by casing (`petSchema` and `PetSchema`). An all-uppercase name such as `SUV`, `URL`, or `API` produced the same identifier for both, so the barrel re-exported it twice and failed to compile with `TS2300: Duplicate identifier`. The `Type` suffix keeps the value and type distinct regardless of casing.

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

The generated Zod also changed: chained syntax instead of functional wrappers, and self-referencing getters only for true cycles. See [Generated output changes: @kubb/plugin-zod](/docs/5.x/migration-guide#kubb-plugin-zod).
