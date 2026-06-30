---
layout: doc
title: Kubb MCP Plugin
description: Generate a Model Context Protocol (MCP) server from OpenAPI so AI
  assistants like Claude can call your API as tools.
outline: deep
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
  - plugin-axios
  - plugin-zod
resources:
  documentation: https://kubb.dev/plugins/plugin-mcp
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/mcp
---

# @kubb/plugin-mcp

`@kubb/plugin-mcp` turns your OpenAPI spec into a [Model Context Protocol](https://modelcontextprotocol.io/introduction) server. Each operation becomes one MCP tool. AI assistants like Claude Desktop and Claude Code call those tools to reach your API. The plugin generates the tool handlers and the Zod schemas that validate each call.

Each handler calls a registered client plugin, so you must add `@kubb/plugin-axios` or `@kubb/plugin-fetch` alongside `@kubb/plugin-ts` and `@kubb/plugin-zod`. Without a client plugin, the build stops with a setup error.

This plugin generates an MCP server from your spec. It is not the same as the built-in `kubb mcp` server that exposes the Kubb CLI itself, which is documented under [AI / MCP](/docs/5.x/ai/mcp).

The [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop) guide explains how to register the generated server with an assistant.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-mcp@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-mcp@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-mcp@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-mcp@beta
```

:::

## Dependencies

This plugin needs three other plugins. Kubb runs them before `plugin-mcp` so the handlers can import the generated types, Zod schemas, and the client functions they call.

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the request and response types.
- [`@kubb/plugin-zod`](/plugins/plugin-zod/) for the schemas that validate each tool call.
- [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) for the HTTP client the handlers call.

A client plugin is required. The handlers call its generated functions, so the build stops with a setup error when no client plugin is registered. Register one of them and set [`client`](#client) only when both are present.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginZod(),
    pluginMcp({
      output: { path: 'mcp', barrel: { type: 'named' } },
      client: 'axios',
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Handlers`,
      },
    }),
  ],
})
```

:::

## See Also

- [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md)
