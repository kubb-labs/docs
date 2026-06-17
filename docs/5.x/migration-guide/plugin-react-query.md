---
title: 'Migration: @kubb/plugin-react-query'
description: Configuration changes for @kubb/plugin-react-query when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-react-query`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-react-query`](/plugins/plugin-react-query).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `client` sub-object for HTTP client configuration is unchanged. All other options are unchanged.

## Generated output

The `*MutationKey` type alias is gone, `TData` narrows to 2xx responses, and `enabled`-guarded params are now optional. These changes are shared with [`@kubb/plugin-vue-query`](/docs/5.x/migration-guide/plugin-vue-query). See [Generated output changes: @kubb/plugin-react-query and @kubb/plugin-vue-query](/docs/5.x/migration-guide#kubb-plugin-react-query-and-kubb-plugin-vue-query).
