---
layout: doc
title: A working MCP server from a spec
description: Register the TypeScript, Zod, and one client plugin alongside pluginMcp to generate a working MCP server from an OpenAPI spec.
outline: deep
---

# A working MCP server from a spec

Register `pluginTs()`, `pluginZod()`, and one client plugin alongside `pluginMcp()`, so the handlers get their types, validation schemas, and an HTTP client. With a single client registered the plugin detects it, so [`output`](/plugins/plugin-mcp/reference/options#output) is the only thing left to tune.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ output: { path: 'mcp', mode: 'directory' } }),
  ],
})
```

## Output example

```typescript [src/gen/mcp/getPetById.ts]
import type { GetPetByIdOptions } from '../types/GetPetById'
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol'
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types'
import { getPetById } from '../clients/getPetById'

export async function getPetByIdHandler({ path }: GetPetByIdOptions, request: RequestHandlerExtra<ServerRequest, ServerNotification>): Promise<Promise<CallToolResult>> {
  const res = await getPetById({ path })

  return {
    content: [{ type: 'text', text: JSON.stringify(res.data) }],
    structuredContent: { data: res.data },
  }
}
```

The handler calls `getPetById` from the Axios client the plugin auto-detected, and `server.ts` registers a matching tool with Zod input and output schemas, so the same file also exports a ready-to-run server.

```typescript [usage.ts]
import { startServer } from './src/gen/mcp/server'

await startServer()
```
