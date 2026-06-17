---
title: 'Migration: @kubb/plugin-mcp'
description: Changes for @kubb/plugin-mcp when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-mcp`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-mcp`](/plugins/plugin-mcp).

The plugin options are unchanged. `transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver).

## Generated output

Handlers receive the MCP `RequestHandlerExtra` object as a second argument and forward it to the underlying client. Existing tools must be updated to thread it through.

::: code-group

```typescript [v4]
import type { CallToolResult } from '@modelcontextprotocol/sdk/types'

export async function addPetHandler({ data }: { data: AddPetMutationRequest }): Promise<CallToolResult> {
  const res = await fetch<AddPetMutationResponse, ResponseErrorConfig<AddPet405>, AddPetMutationRequest>({
    method: 'POST',
    url: '/pet',
    baseURL: 'https://petstore.swagger.io/v2',
    data,
  })
  ...
}
```

```typescript [v5]
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types'
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol'

export async function addPetHandler(
  { data }: { data: AddPetData },
  request: RequestHandlerExtra<ServerRequest, ServerNotification>,
): Promise<CallToolResult> {
  const res = await client<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>(
    { method: 'POST', url: `/pet`, baseURL: `https://petstore.swagger.io/v2`, data },
    request,
  )
  ...
}
```

:::
