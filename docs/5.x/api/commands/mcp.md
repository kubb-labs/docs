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

```shell [Terminal]
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

> [!TIP]
> `@kubb/mcp` ships as a dependency of the `kubb` package, so you need no extra install when you already use `kubb`.

## Transport

`kubb mcp` runs over stdio. The server reads from standard input and writes to standard output, matching the [Model Context Protocol](https://modelcontextprotocol.io/) transport used by Claude Desktop, Cursor, VS Code, and other editor integrations. The client launches the server as a subprocess, so it needs no flags, port, or host.

## Tools

The MCP server exposes three tools to connected clients.

| Tool       | Description                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `generate` | Runs the Kubb pipeline against a resolved `kubb.config.ts` and streams log messages back to the client.                              |
| `validate` | Validates an OpenAPI or Swagger document at a path or URL. Needs `@kubb/adapter-oas` installed in the project.                       |
| `init`     | Scaffolds a `kubb.config.ts` in the current directory without prompts. It does not install packages.                                |

### Structured diagnostics

When `generate` or `validate` hits a problem, it returns structured [diagnostics](/docs/5.x/api/diagnostics)
instead of a single message string. Each diagnostic keeps its stable code, source pointer,
suggested fix, and docs link, so an assistant can act on the exact problem. The tools return a
readable text block and a JSON payload:

```text [Terminal]
error @kubb/plugin-zod(KUBB_REF_NOT_FOUND): Could not find a definition for #/components/schemas/Pet.
  at #/components/schemas/Pet
  help: Add the schema under components.schemas, or fix the $ref.
  docs: https://kubb.dev/docs/5.x/api/diagnostics/kubb-ref-not-found
```

A missing spec passed to `validate` returns the coded [`KUBB_INPUT_NOT_FOUND`](/docs/5.x/api/diagnostics/kubb-input-not-found)
diagnostic, the same code the CLI reports.

## Example client configuration

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

- [`@kubb/mcp`](/plugins/plugin-mcp), the plugin docs with the full list of tools the MCP server exposes
- [Concepts: Plugins](/docs/5.x/guide/concepts/plugins): how plugins integrate with the Kubb pipeline
