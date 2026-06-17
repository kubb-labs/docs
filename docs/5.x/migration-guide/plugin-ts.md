---
title: 'Migration: @kubb/plugin-ts'
description: Configuration changes for @kubb/plugin-ts when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-ts`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-ts`](/plugins/plugin-ts).

## Removed: `mapper`

```typescript [v4 kubb.config.ts]
pluginTs({ mapper: { status: 'string' } })
```

Use [`printer.nodes`](/plugins/plugin-ts#printer) to override specific schema-type renderers, or [`macros`](/plugins/plugin-ts#macros) to rewrite AST nodes before printing.

## Renamed: `transformers.name`

`transformers.name` is replaced by [`resolver.resolveTypeName`](/docs/5.x/migration-guide#transformersname-resolver).

## Moved to `adapterOas`

`dateType`, `integerType`, `unknownType`, `emptySchemaType`, `enumSuffix`, and `contentType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas).

## Generated output

The generated TypeScript also changed: object-literal enums, `int64` mapping to `bigint`, open string unions, JSDoc tweaks, and factored discriminated unions. See [Generated output changes: @kubb/plugin-ts](/docs/5.x/migration-guide#kubb-plugin-ts).
