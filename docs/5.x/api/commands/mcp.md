---
layout: doc
title: kubb mcp
description: The mcp command starts a Model Context Protocol server so LLM clients can interact with your schemas and trigger generation.
outline: [2, 3]
---

# `kubb mcp`

Starts a [Model Context Protocol](https://modelcontextprotocol.io/) server that lets LLM clients (Claude, Cursor, VS Code, and others) interact with your schemas and trigger generation.

> [!WARNING]
> This feature is still under active development. Use it with caution and expect breaking changes.

```terminal
command: kubb mcp
output:
  - ⏳ Starting MCP server...
  - This feature is still under development, use with caution
```

## Usage

Start the MCP server over stdio (the default transport, used by every major LLM client):

```shell
kubb mcp
```

Start the MCP server over HTTP so clients can reach it as a network endpoint:

```shell
kubb mcp --port 3001
```

> [!TIP]
> `@kubb/mcp` ships as a dependency of the `kubb` meta-package, so no extra install is needed when you already use `kubb`.

## Options

| Option                       | Default     | Description                                                                                                  |
| ---------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------ |
| `--port=<port>`, `-p <port>` |             | Start the server in HTTP mode on the given port. Omit this flag to use the default stdio transport.          |
| `--host=<host>`              | `localhost` | Hostname the HTTP server binds to. Only takes effect when `--port` is also set.                              |

## Transport

`kubb mcp` supports two transports.

The default is stdio: the server reads from standard input and writes to standard output, matching the [Model Context Protocol](https://modelcontextprotocol.io/) transport used by Claude Desktop, Cursor, VS Code, and other editor integrations. No flags are required.

Pass `--port` to switch to HTTP. The server exposes `http://<host>:<port>/mcp` and accepts requests from hosted MCP clients or any machine that can reach the host.

```terminal
command: kubb mcp --port 3001
output:
  - ⏳ Starting MCP server...
  - This feature is still under development, use with caution
  - Kubb MCP server on http://localhost:3001
```

## Tools

The MCP server exposes three tools to connected clients.

| Tool       | Description                                                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `generate` | Runs the Kubb code-generation pipeline against a resolved `kubb.config.ts` and streams log messages back to the client.              |
| `validate` | Validates an OpenAPI or Swagger document at a path or URL. Requires `@kubb/adapter-oas` to be installed in the project.              |
| `init`     | Scaffolds a `kubb.config.ts` in the current directory without prompts. The tool does not install packages.                           |

### Structured diagnostics

When `generate` or `validate` hits a problem, it returns structured [diagnostics](/docs/5.x/reference/diagnostics)
instead of a single message string. Each diagnostic keeps its stable code, source pointer,
suggested fix, and docs link, so an assistant can act on the exact problem. The tools return both a
readable text block and a JSON payload:

```text
error @kubb/plugin-zod(KUBB_REF_NOT_FOUND): Could not find a definition for #/components/schemas/Pet.
  at #/components/schemas/Pet
  help: Add the schema under components.schemas, or fix the $ref.
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-ref-not-found
```

A missing spec passed to `validate` returns the coded [`KUBB_INPUT_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-input-not-found)
diagnostic, the same code the CLI reports.

## Example client configuration

Most MCP clients accept a JSON config with a `command` and `args`. To register the Kubb MCP server over stdio:

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

For HTTP-capable clients, point them at the HTTP endpoint instead:

```json
{
  "mcpServers": {
    "kubb": {
      "url": "http://localhost:3001/mcp"
    }
  }
}
```

## See also

- [`@kubb/mcp`](/plugins/plugin-mcp), the plugin docs with the full list of tools the MCP server exposes
- [Concepts: Plugins](/docs/5.x/concepts/plugins): how plugins integrate with the Kubb pipeline
