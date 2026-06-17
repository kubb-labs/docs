---
title: 'Migration: @kubb/plugin-faker'
description: Configuration changes for @kubb/plugin-faker when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-faker`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-faker`](/plugins/plugin-faker).

`dateType`, `integerType`, `unknownType`, and `emptySchemaType` moved to [`adapterOas`](/adapters/adapter-oas). See [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas). The `transformers.name` callback is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). All other options are unchanged.

## Generated output

The generator now returns `Required<T>` and builds an intermediate variable before spreading overrides. See [Generated output changes: @kubb/plugin-faker](/docs/5.x/migration-guide#kubb-plugin-faker).
