---
layout: doc
title: kubb mcp
description: The mcp command starts a Model Context Protocol server so LLM clients can interact with your schemas and trigger generation.
outline: [2, 3]
---

# `kubb mcp`

Run `kubb mcp` to start a [Model Context Protocol](https://modelcontextprotocol.io/) server. LLM clients such as Claude, Cursor, and VS Code can then read your schemas and trigger generation.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

```terminal
command: kubb mcp
output:
  - ⏳ Starting MCP server...
  - This feature is still under development, use with caution
```

## Usage

Start the MCP server over stdio, the transport every major LLM client speaks:

```shell [Terminal]
kubb mcp
```

## Tools

The MCP server exposes three tools to connected clients.

| Tool       | Description                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `generate` | Runs the Kubb pipeline against a resolved `kubb.config.ts` and streams log messages back to the client.                              |
| `validate` | Validates an OpenAPI or Swagger document at a path or URL. Needs `@kubb/adapter-oas` installed in the project.                       |
| `init`     | Scaffolds a `kubb.config.ts` in the current directory without prompts. It does not install packages.                                |

## Example

Most MCP clients accept a JSON config with a `command` and `args`. To register the Kubb MCP server over stdio:

```json [mcp.json]
{
  "mcpServers": {
    "kubb": {
      "command": "npx",
      "args": ["kubb", "mcp"]
    }
  }
}
```

## See also

- [MCP integration guide](/docs/5.x/ai/mcp): connect the server to Claude Desktop, Cursor, and other clients
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp/), a different package that generates an MCP server from your OpenAPI spec
- [Concepts: Plugins](/docs/5.x/guide/concepts/plugins): how plugins integrate with the Kubb pipeline
