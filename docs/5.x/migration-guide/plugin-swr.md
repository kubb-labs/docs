---
title: 'Migration: @kubb/plugin-swr'
description: Configuration changes for @kubb/plugin-swr when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-swr`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-swr`](/plugins/plugin-swr).

`@kubb/plugin-swr` follows the same conventions as the React Query and Vue Query plugins. [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

SWR has no `enabled` option, so the param-presence guard folds into the null-key gate (`useSWR(shouldFetch && !!(petId) ? queryKey : null, ...)`). Passing `undefined` disables the request.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each hook now takes its parameters as a single grouped options object with camelCase property names. Query and header params move under a `params` key, and path params become named properties.

```diff [Diff]
  pluginSwr({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

Update the call sites. Query params move into `params`, and path params become an object:

```typescript [Generated output]
// Before
useFindPetsByStatus({ status: 'available' })
useUpdatePet(2)

// After
useFindPetsByStatus({ params: { status: 'available' } })
useUpdatePet({ petId: 2 })
```
