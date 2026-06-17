---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-swr`](/plugins/plugin-swr).

`@kubb/plugin-swr` follows the same conventions as the React Query and Vue Query plugins: [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) takes over from `transformers.name`, and the `client` sub-object stays the same.

SWR has no `enabled` option, so the param-presence guard folds into the null-key gate (`useSWR(shouldFetch && !!(petId) ? queryKey : null, ...)`). Passing `undefined` disables the request.
