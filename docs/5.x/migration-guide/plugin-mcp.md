---
title: 'Migration: @kubb/plugin-mcp'
description: Changes for @kubb/plugin-mcp when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-mcp`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`, and the `generators` option is [gone](/docs/5.x/migration-guide#generators-removed).

## `client` selects a registered client plugin

In v4, `client` was an object that configured a bundled client: `clientType`, `dataReturnType`, `baseURL`, `bundle`, `importPath`, and `paramsCasing`. v5 drops all of those. The handlers now call a registered client plugin, so `client` is a single string that picks which one: `'axios'` or `'fetch'`. Register [`@kubb/plugin-axios`](/plugins/plugin-axios) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch) in `plugins`, and set `baseURL` there instead of on `pluginMcp`. When exactly one client plugin is registered, Kubb auto-detects it and the string is optional.

`pluginMcp` also depends on [`@kubb/plugin-ts`](/plugins/plugin-ts) and [`@kubb/plugin-zod`](/plugins/plugin-zod), so register both alongside the client plugin.

::: code-group

```typescript [v4 kubb.config.ts]
import { defineConfig } from '@kubb/core'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginMcp({
      client: {
        client: 'fetch',
        baseURL: 'https://petstore.swagger.io/v2',
      },
    }),
  ],
})
```

```typescript [v5 kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginFetch({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ client: 'fetch' }),
  ],
})
```

:::

## Removed: `paramsCasing`

```typescript [v4 kubb.config.ts]
pluginMcp({ paramsCasing: 'camelcase' })
```

Parameter properties in the generated handlers are now always camelCase, including the `client.paramsCasing` sub-option, so drop both. The HTTP layer still uses the original spec names, and Kubb writes the mapping for you.

## Generated output

Each handler now takes a second argument, the MCP `RequestHandlerExtra` object, so it can read the request context. The handler no longer builds the request inline. Instead it calls the named operation from the registered client plugin (`addPet` here) with a single grouped `{ path, query, headers, body }` config object, and reads `res.data`.

```typescript [Generated output]
import type { CallToolResult } from '@modelcontextprotocol/sdk/types' // [!code --]
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types' // [!code ++]
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol' // [!code ++]
import { addPet } from './clients/addPet' // [!code ++]

export async function addPetHandler({ data }: { data: AddPetMutationRequest }): Promise<CallToolResult> { // [!code --]
export async function addPetHandler( // [!code ++]
  { body }: AddPetRequestConfig, // [!code ++]
  request: RequestHandlerExtra<ServerRequest, ServerNotification>, // [!code ++]
): Promise<CallToolResult> { // [!code ++]
  const res = await fetch<AddPetMutationResponse, ResponseErrorConfig<AddPet405>, AddPetMutationRequest>({ // [!code --]
    method: 'POST', // [!code --]
    url: '/pet', // [!code --]
    baseURL: 'https://petstore.swagger.io/v2', // [!code --]
    data, // [!code --]
  }) // [!code --]
  const res = await addPet({ body }) // [!code ++]
  ...
}
```
