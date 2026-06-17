---
title: 'Migration: @kubb/plugin-cypress'
description: Changes for @kubb/plugin-cypress when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-cypress`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-cypress`](/plugins/plugin-cypress).

The plugin options are unchanged. `transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver).

## Generated output

HTTP method constants are uppercased and imports follow the new `*Data` / `*Response` naming. See [Generated output changes: @kubb/plugin-cypress](/docs/5.x/migration-guide#kubb-plugin-cypress).
