---
layout: doc
title: Kubb MCP Plugin
description: Generates a Model Context Protocol server from your OpenAPI spec,
  so AI assistants can call each operation as a typed tool.
outline: deep
guides:
  - id: server
    title: Run an MCP server
kind: plugin
id: plugin-mcp
name: MCP
category: ai
type: official
npmPackage: "@kubb/plugin-mcp"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-mcp
featured: false
icon:
  light: https://kubb.dev/feature/mcp-light.svg
  dark: https://kubb.dev/feature/mcp-dark.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - mcp
  - model-context-protocol
  - ai
  - claude
  - llm
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-zod
resources:
  documentation: https://kubb.dev/plugins/plugin-mcp
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/mcp
---

# @kubb/plugin-mcp

Generate an MCP server from OpenAPI.

- Tools and handlers call a generated HTTP client.
- Zod schemas validate tool input.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-mcp
```

```shell [pnpm]
pnpm add -D @kubb/plugin-mcp
```

```shell [npm]
npm install --save-dev @kubb/plugin-mcp
```

```shell [yarn]
yarn add -D @kubb/plugin-mcp
```

::

## Dependencies

- Add [`pluginTs`](/plugins/plugin-ts/), [`pluginZod`](/plugins/plugin-zod/), and an [Axios](/plugins/plugin-axios/) or [Fetch](/plugins/plugin-fetch/) client plugin.
- Set [`client`](/plugins/plugin-mcp/reference/options#client) when both clients are configured.
- Generated servers require `@modelcontextprotocol/sdk` v1 or higher.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginFetch({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginMcp({ output: { path: 'mcp', mode: 'directory' } }),
  ],
})
```

## See also

- [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop)
