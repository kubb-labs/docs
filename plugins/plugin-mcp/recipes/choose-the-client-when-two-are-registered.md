---
layout: doc
title: Choose the client when two are registered
description: Set the client option so the MCP handlers know which HTTP client to call when both the Axios and Fetch plugins are registered.
outline: deep
---

# Choose the client when two are registered

Set [`client`](/plugins/plugin-mcp/reference/options#client) to `'axios'` or `'fetch'` when both client plugins are present, so the handlers know which one to call.

```typescript twoslash [kubb.config.ts]
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
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginFetch({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ client: 'axios' }),
  ],
})
```
