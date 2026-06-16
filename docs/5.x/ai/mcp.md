---
layout: doc
title: MCP - AI
description: Connect AI editors and agents to Kubb's local MCP server. Configure Claude Desktop, Cursor, VS Code, and other MCP-capable clients to run Kubb tools directly.
outline: [2, 3]
---

# MCP

Kubb ships a [Model Context Protocol](https://modelcontextprotocol.io/) server that exposes code-generation tools to any MCP-capable client. Once connected, your editor or agent runs Kubb generation, validates schemas, and inspects configuration without leaving the chat.

> [!IMPORTANT]
> The built-in MCP server requires Kubb v5 or higher.

> [!NOTE]
> This page covers consuming Kubb tooling inside your editor via MCP. If you want to generate an MCP server from your OpenAPI spec, see [`@kubb/plugin-mcp`](/plugins/plugin-mcp) instead.

## Starting the server

Run the MCP server over stdio with a single command:

```shell
kubb mcp
```

It communicates over stdio, the transport every major LLM client speaks.

## Client configuration

### Claude Desktop

Add the following to your `claude_desktop_config.json` (usually at `~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
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

Open `Settings → MCP` and add a new server entry:

```json
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

Add the following to your `.vscode/mcp.json` (workspace), or run `MCP: Open User Configuration` in the Command Palette for a global setup:

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

- [`kubb mcp` command](/docs/5.x/api/commands/mcp): CLI reference with all flags and transport details
- [`@kubb/plugin-mcp`](/plugins/plugin-mcp) generates an MCP server from your OpenAPI spec
