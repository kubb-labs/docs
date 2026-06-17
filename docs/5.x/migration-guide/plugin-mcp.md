---
title: 'Migration: @kubb/plugin-mcp'
description: Changes for @kubb/plugin-mcp when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-mcp`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-mcp`](/plugins/plugin-mcp).

The plugin options are unchanged. `transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver).

## Generated output

Handlers receive the MCP `RequestHandlerExtra` object as a second argument and forward it to the underlying client. Existing tools must be updated to thread it through. See [Generated output changes: @kubb/plugin-mcp](/docs/5.x/migration-guide#kubb-plugin-mcp).
