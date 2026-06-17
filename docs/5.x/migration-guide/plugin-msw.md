---
title: 'Migration: @kubb/plugin-msw'
description: Configuration changes for @kubb/plugin-msw when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-msw`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-msw`](/plugins/plugin-msw).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `contentType` option moved to [`adapterOas`](/adapters/adapter-oas), covered in [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas). All other options are unchanged.

## Generated output

Handlers are now strongly typed against the request body and headers, and accept an `HttpResponseResolver` callback. See [Generated output changes: @kubb/plugin-msw](/docs/5.x/migration-guide#kubb-plugin-msw).
