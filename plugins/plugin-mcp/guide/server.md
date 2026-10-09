---
layout: doc
title: Run an MCP server
description: Generate and start an MCP server with typed tools and an HTTP client.
outline: deep
---

# Run an MCP server

::steps{level="2"}

## Generate the server

Register TypeScript types, Zod schemas, and an Axios or Fetch client alongside `pluginMcp`. A single registered client is detected automatically.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs({ output: { path: 'types', mode: 'directory' } }),
    pluginZod(),
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ output: { path: 'mcp', mode: 'directory' } }),
  ],
})
```

Run `kubb generate`. The plugin writes tool handlers, `server.ts`, and `.mcp.json`. Each generated handler calls its HTTP operation, forwards the cancellation signal, and throws for non-2xx responses. Tool results include text content and structured response data. `server.ts` registers tools with Zod input and output schemas.

## Start the server

Install the generated server's runtime dependencies and a TypeScript runner:

```shell [Terminal]
npm install @modelcontextprotocol/sdk@^1 zod@^4 axios@^1
npm install -D tsx
```

Import the generated `startServer` function.

```typescript [server.ts]
import { startServer } from './src/gen/mcp/server'

await startServer()
```

Run the entry point:

```shell [Terminal]
npx tsx server.ts
```

::

## Select a client

When both HTTP plugins are registered, set [`client`](/plugins/plugin-mcp/reference/options#client) explicitly. Give each client a different output directory so their generated files do not overwrite each other.

```typescript [kubb.config.ts]
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginMcp } from '@kubb/plugin-mcp'

const clients = [
  pluginAxios({ output: { path: 'clients-axios', mode: 'directory' } }),
  pluginFetch({ output: { path: 'clients-fetch', mode: 'directory' } }),
  pluginMcp({ output: { path: 'mcp', mode: 'directory' }, client: 'axios' }),
]
```

Add these entries alongside `pluginTs` and `pluginZod` in `defineConfig.plugins`. The handlers import operations from `clients-axios`.
