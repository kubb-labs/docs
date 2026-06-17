---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-swr`](/plugins/plugin-swr).

`@kubb/plugin-swr` was unavailable during the early v5 betas but is supported again in v5. It follows the same conventions as the React Query and Vue Query plugins: `transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver), and the `client` sub-object is unchanged.

Since SWR has no `enabled` option, the param-presence guard folds into the null-key gate (`useSWR(shouldFetch && !!(petId) ? queryKey : null, ...)`), so passing `undefined` disables the request.
