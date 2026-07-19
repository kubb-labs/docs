---
layout: doc
title: Choose the client when two are registered
description: Set the client option so the MCP handlers know which HTTP client to call when both the Axios and Fetch plugins are registered.
outline: deep
---

# Choose the client when two are registered

Set [`client`](/plugins/plugin-mcp/reference/options#client) to `'axios'` or `'fetch'` when both client plugins are present, so the handlers know which one to call. [`pluginAxios`](/plugins/plugin-axios/reference/options#output-path) and [`pluginFetch`](/plugins/plugin-fetch/reference/options#output-path) both default `output.path` to `clients`, so give each its own path here too, otherwise the second one registered overwrites the first's generated files.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginAxios({ output: { path: './clients-axios' }, baseURL: 'https://petstore.swagger.io/v2' }),
    pluginFetch({ output: { path: './clients-fetch' }, baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ output: { path: 'mcp', mode: 'directory' }, client: 'axios' }),
  ],
})
```

## Output example

```typescript [src/gen/mcp/getPetById.ts]
import type { GetPetByIdOptions } from '../types/GetPetById'
import type { RequestHandlerExtra } from '@modelcontextprotocol/sdk/shared/protocol'
import type { CallToolResult, ServerNotification, ServerRequest } from '@modelcontextprotocol/sdk/types'
import { getPetById } from '../clients-axios/getPetById'

export async function getPetByIdHandler({ path }: GetPetByIdOptions, request: RequestHandlerExtra<ServerRequest, ServerNotification>): Promise<Promise<CallToolResult>> {
  const res = await getPetById({ path })

  return {
    content: [{ type: 'text', text: JSON.stringify(res.data) }],
    structuredContent: { data: res.data },
  }
}
```

Even with `pluginFetch` also registered, the handler imports from `clients-axios`, the path given to `pluginAxios`, because `client: 'axios'` picked it.

```typescript [usage.ts]
import { startServer } from './src/gen/mcp/server'

await startServer()
```
