---
layout: doc
title: Set up the MCP server
description: Connect AI editors and agents to Kubb's local MCP server. Configure Claude Desktop, Cursor, VS Code, and other MCP-capable clients to run Kubb tools directly.
outline: [2, 3]
---

# Set up the MCP server

Kubb ships a [Model Context Protocol](https://modelcontextprotocol.io/) server. It exposes
code-generation tools to any MCP-capable client. Once connected, your editor or agent runs Kubb
generation, validates schemas, and inspects configuration from the chat.

> [!IMPORTANT]
> The built-in MCP server needs Kubb v5 or higher.

> [!NOTE]
> This page covers using Kubb tooling inside your editor over MCP. To generate an MCP server from
> your OpenAPI spec, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp) instead.

## Starting the server

Run the server with one command. It communicates over stdio, the transport that every major LLM
client speaks.

```shell [Terminal]
kubb mcp
```

## Client configuration

### Claude Desktop

Add this to your `claude_desktop_config.json`. On macOS it usually lives at `~/Library/Application Support/Claude/claude_desktop_config.json`.

```json [Claude Desktop]
{
  "mcpServers": {
    "kubb": {
      "command": "npx",
      "args": ["kubb", "mcp"]
    }
  }
}
```

### Cursor

Open `Settings → MCP` and add a new server entry.

```json [Cursor]
{
  "mcpServers": {
    "kubb": {
      "command": "npx",
      "args": ["kubb", "mcp"]
    }
  }
}
```

### VS Code (GitHub Copilot)

Add this to your `.vscode/mcp.json` for the workspace. For a global setup, run `MCP: Open User Configuration` in the Command Palette.

```json [.vscode/mcp.json]
{
  "servers": {
    "kubb": {
      "command": "npx",
      "args": ["kubb", "mcp"]
    }
  }
}
```

## See also

- [`kubb mcp` command](/docs/5.x/reference/commands/mcp): CLI reference and transport details
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp) generates an MCP server from your OpenAPI spec
