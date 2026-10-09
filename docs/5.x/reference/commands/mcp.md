---
layout: doc
title: kubb mcp
description: The mcp command starts a Model Context Protocol server so LLM
  clients can interact with your schemas and trigger generation.
outline:
  - 2
  - 3
order: 4
navigation:
  title: kubb mcp
  icon: i-simple-icons-modelcontextprotocol
---

# kubb mcp

Run `kubb mcp` to start a [Model Context Protocol](https://modelcontextprotocol.io/) server. LLM clients such as Claude, Cursor, and VS Code can then read your schemas and trigger generation.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

::terminal
---
command: kubb mcp
output:
  - ⏳ Starting MCP server...
  - This feature is still under development, use with caution
---
::

The server speaks stdio, the transport every major MCP client supports. [Set up the MCP server](/docs/5.x/ai/mcp) shows the client configuration.

## Tools

| Tool       | Parameters | Description |
| ---------- | ---------- | ----------- |
| `generate` | `config?` (path to a config file, default `kubb.config.{ts,js,cjs}` in the current directory), `input?` (spec path, overrides the config), `output?` (output directory, overrides the config), `logLevel?` (`silent`, `info`, `verbose`, default `info`) | Runs the Kubb pipeline and streams log messages back to the client. |
| `validate` | `input` (path or URL, required) | Validates an OpenAPI or Swagger document with the bundled OpenAPI adapter. |
| `init`     | `input?` (default `./openapi.yaml`), `output?` (default `./src/gen`), `plugins?` (comma-separated, such as `plugin-ts,plugin-zod`) | Writes a `kubb.config.ts` in the current directory without prompts. It does not install packages. |

## See also

- [Set up the MCP server](/docs/5.x/ai/mcp): connect the server to Claude Desktop, Cursor, and VS Code
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp/), a different package that generates an MCP server from your OpenAPI spec
- [Concepts: Plugins](/docs/5.x/explanation/extensions#plugins): how plugins integrate with the Kubb pipeline
