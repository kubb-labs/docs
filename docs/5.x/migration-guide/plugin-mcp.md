---
title: 'Migration: @kubb/plugin-mcp'
description: Changes for @kubb/plugin-mcp when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-mcp`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Removed: `paramsCasing`

```typescript [v4 kubb.config.ts]
pluginMcp({ paramsCasing: 'camelcase' })
```

Parameter properties in the generated handlers are now always camelCase, including the `client.paramsCasing` sub-option, so drop both. The HTTP layer still uses the original spec names, and Kubb writes the mapping for you.

## Generated output

Handlers take the MCP `RequestHandlerExtra` object as a second argument and forward it to the client. Update existing tools to thread it through.

```typescript [Generated output]
import type { CallToolResult } from '@modelcontextprotocol/sdk/types' // [!code --]
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types' // [!code ++]
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol' // [!code ++]

export async function addPetHandler({ data }: { data: AddPetMutationRequest }): Promise<CallToolResult> { // [!code --]
export async function addPetHandler( // [!code ++]
  { data }: { data: AddPetData }, // [!code ++]
  request: RequestHandlerExtra<ServerRequest, ServerNotification>, // [!code ++]
): Promise<CallToolResult> { // [!code ++]
  const res = await fetch<AddPetMutationResponse, ResponseErrorConfig<AddPet405>, AddPetMutationRequest>({ // [!code --]
    method: 'POST', // [!code --]
    url: '/pet', // [!code --]
    baseURL: 'https://petstore.swagger.io/v2', // [!code --]
    data, // [!code --]
  }) // [!code --]
  const res = await client<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>( // [!code ++]
    { method: 'POST', url: `/pet`, baseURL: `https://petstore.swagger.io/v2`, data }, // [!code ++]
    request, // [!code ++]
  ) // [!code ++]
  ...
}
```
