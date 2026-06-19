---
title: 'Migration: @kubb/plugin-vue-query'
description: Configuration and generated-output changes for @kubb/plugin-vue-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-vue-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone, including `client.paramsCasing`. Each composable now takes its parameters as a single grouped options object with camelCase property names. Query and header params move under a `params` key, and path params become named properties.

```diff [Diff]
  pluginVueQuery({
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

## Generated output

The generated output changes match React Query. The `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, and `enabled`-guarded params become optional. Vue Query writes the guard as `enabled: () => !!toValue(petId)`. See [Generated output: @kubb/plugin-react-query](/docs/5.x/migration-guide/plugin-react-query#generated-output).
