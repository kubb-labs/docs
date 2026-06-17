---
title: 'Migration: @kubb/plugin-mcp'
description: Changes for @kubb/plugin-mcp when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-mcp`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp).

The plugin options stay the same. [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) takes over from `transformers.name`.

## Generated output

Handlers take the MCP `RequestHandlerExtra` object as a second argument and forward it to the underlying client. Update existing tools to thread it through.

```typescript
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
