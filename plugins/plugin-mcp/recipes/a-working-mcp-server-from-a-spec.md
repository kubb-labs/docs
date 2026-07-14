---
layout: doc
title: A working MCP server from a spec
description: Register the TypeScript, Zod, and one client plugin alongside pluginMcp to generate a working MCP server from an OpenAPI spec.
outline: deep
---

# A working MCP server from a spec

Register `pluginTs()`, `pluginZod()`, and one client plugin alongside `pluginMcp()`, so the handlers get their types, validation schemas, and an HTTP client. With a single client registered the plugin detects it, so [`output`](/plugins/plugin-mcp/reference/options#output) is the only thing left to tune.

```typescript twoslash [kubb.config.ts]
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
    pluginMcp(),
  ],
})
```
