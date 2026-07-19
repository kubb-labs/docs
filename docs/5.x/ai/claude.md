---
layout: doc
title: Set up the Claude Code plugin
description: The Kubb Claude Code plugin adds slash commands and an agent that run Kubb code generation from inside Claude Code.
outline: [2, 3]
---

# Set up the Claude Code plugin

Kubb ships a [Claude Code](https://code.claude.com) plugin. It adds slash commands and an agent
that generate code from an OpenAPI spec. The commands run the `kubb` CLI, so a build you start in
the chat matches the one you run in a terminal.

> [!IMPORTANT]
> The plugin needs Kubb v5 or higher. It targets the v5 CLI and the built-in MCP server.

> [!NOTE]
> This page covers the Claude Code plugin. To generate an MCP server from your spec and drive it
> from Claude Desktop, see the [Claude MCP guide](/docs/5.x/guide/going-further/claude-mcp-plugin) instead.

## Install

The Kubb repository is also a plugin marketplace. Add it, then install the plugin:

```shell [Terminal]
/plugin marketplace add kubb-labs/kubb
/plugin install kubb@kubb
```

The commands run `npx kubb`, so install Kubb yourself, either in the project or globally:

```shell [Terminal]
npm install -D kubb@beta
```

A `SessionStart` hook checks for `kubb` at session start and warns you if it's missing, but it
never installs anything for you.

`kubb init` installs the `@kubb/plugin-*` packages you select.

## Commands

The commands mirror the Kubb CLI, namespaced under `kubb:`.

| Command | What it does |
| --- | --- |
| `/kubb:init [input] [output] [plugins]` | Scaffold `kubb.config.ts` and install plugins with `kubb init`. |
| `/kubb:generate [input]` | Run `kubb generate` and report what changed. |
| `/kubb:validate <spec>` | Validate an OpenAPI or Swagger spec with `kubb validate`. |

A typical first run:

```text [Terminal]
/kubb:validate ./petStore.yaml
/kubb:init ./petStore.yaml ./src/gen plugin-ts,plugin-zod,plugin-react-query
/kubb:generate
```

## Agent

The `kubb-expert` agent handles "add Kubb to my project" from start to finish. It validates the
spec, picks plugins, scaffolds the config, and runs generation.

## Conversational generation

The plugin also wires in the Kubb MCP server (`kubb mcp`). Describe what you want instead of
typing a command, and Claude calls the server directly. See [MCP](/docs/5.x/ai/mcp) for setup.

## See also

- [MCP](/docs/5.x/ai/mcp): connect AI editors directly to Kubb's MCP server
- [Claude MCP guide](/docs/5.x/guide/going-further/claude-mcp-plugin): generate an MCP server from your spec
