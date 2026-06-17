---
title: 'Migration: @kubb/plugin-vue-query'
description: Configuration and generated-output changes for @kubb/plugin-vue-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-vue-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) takes over from `transformers.name`. The `client` sub-object for HTTP client configuration stays the same, as do all other options.

## Generated output

The generated output changes match React Query: the `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, and `enabled`-guarded params become optional (Vue Query writes the guard as `enabled: () => !!toValue(petId)`). See [Generated output: @kubb/plugin-react-query](/docs/5.x/migration-guide/plugin-react-query#generated-output).
