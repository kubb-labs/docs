---
layout: doc
title: Kubb MCP Plugin
description: Generates a Model Context Protocol server from your OpenAPI spec, so
  AI assistants can call each operation as a typed tool.
outline: deep
recipes:
  - id: a-working-mcp-server-from-a-spec
    title: A working MCP server from a spec
  - id: choose-the-client-when-two-are-registered
    title: Choose the client when two are registered
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

`@kubb/plugin-mcp` turns your OpenAPI spec into a [Model Context Protocol](https://modelcontextprotocol.io/introduction) server, with each operation becoming an MCP tool that AI assistants like Claude Desktop and Claude Code can call to reach your API. The plugin generates the tool handlers, a `server.ts`, and a `.mcp.json`, and validates each call with the schemas from `@kubb/plugin-zod`.

Each handler calls a registered client plugin, so add `@kubb/plugin-axios` or `@kubb/plugin-fetch` alongside `@kubb/plugin-ts` and `@kubb/plugin-zod`. Without a client plugin, the build stops with a setup error.

This plugin generates an MCP server from your spec, distinct from the built-in `kubb mcp` server that exposes the Kubb CLI itself, documented under [AI / MCP](/docs/5.x/ai/mcp).

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

This plugin needs three other plugins. `@kubb/plugin-ts` and `@kubb/plugin-zod` are declared dependencies, so Kubb runs them before `plugin-mcp` and the handlers can import the generated types and Zod schemas. The client plugin is resolved separately at setup.

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the request and response types.
- [`@kubb/plugin-zod`](/plugins/plugin-zod/) for the schemas that validate each tool call.
- [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) for the HTTP client the handlers call.

A client plugin is required, since the handlers call its generated functions. Register one of them and set [`client`](/plugins/plugin-mcp/reference/options#client) only when both are present.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginMcp } from '@kubb/plugin-mcp'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios({ baseURL: 'https://petstore.swagger.io/v2' }),
    pluginZod(),
    pluginMcp({
      output: { path: 'mcp', mode: 'directory', barrel: { type: 'named' } },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Handlers`,
      },
    }),
  ],
})
```

:::

## See also

- [Connect Claude to a remote MCP server](https://modelcontextprotocol.io/docs/tools/claude-desktop)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-mcp/CHANGELOG.md)
