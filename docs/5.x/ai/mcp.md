---
layout: doc
title: Set up the MCP server
description: Connect AI editors and agents to Kubb's local MCP server. Configure
  Claude Desktop, Cursor, VS Code, and other MCP-capable clients to run Kubb
  tools directly.
outline:
  - 2
  - 3
order: 3
navigation:
  title: MCP
  icon: i-simple-icons-modelcontextprotocol
---

# Set up the MCP server

Kubb ships a [Model Context Protocol](https://modelcontextprotocol.io/) server that exposes
code-generation tools to any MCP-capable client. Once connected, your editor or agent runs Kubb
generation, validates schemas, and scaffolds configuration from the chat.

> [!NOTE]
> This page covers using Kubb tooling inside your editor over MCP. To generate an MCP server from
> your OpenAPI spec, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp/) instead.

## Client configuration {#client-configuration}

The server starts with `kubb mcp` over stdio and exposes the `generate`, `validate`, and `init` tools listed in the [command reference](/docs/5.x/reference/commands/mcp#tools). Register it with the same entry in each client.

### Claude Desktop and Cursor

Add the entry to `claude_desktop_config.json` (on macOS under `~/Library/Application Support/Claude/`, on Windows under `%APPDATA%\Claude\`) or to the server list under Cursor's `Settings → MCP`.

```json [claude_desktop_config.json]
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

VS Code uses a `servers` key instead. Add this to `.vscode/mcp.json` for the workspace, or run `MCP: Open User Configuration` in the Command Palette for a global setup.

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
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp/) generates an MCP server from your OpenAPI spec
