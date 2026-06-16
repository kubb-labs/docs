---
layout: doc
title: Claude - AI
description: The Kubb Claude Code plugin adds slash commands, a config skill and an agent that run Kubb code generation from inside Claude Code.
outline: [2, 3]
---

# Claude Code plugin

Kubb ships a [Claude Code](https://code.claude.com) plugin that adds slash commands, a config
skill, and an agent for generating code from an OpenAPI spec. The commands run the `kubb` CLI, so
a build started in the chat matches the one you run in a terminal.

> [!IMPORTANT]
> The plugin requires Kubb v5 or higher. It targets the v5 CLI and the built-in MCP server.

> [!NOTE]
> This page covers the Claude Code plugin. To generate an MCP server from your spec and drive it
> from Claude Desktop, see the [Claude MCP guide](/docs/5.x/guides/claude-mcp-plugin) instead.

## Install

The Kubb repository doubles as a plugin marketplace. Add the marketplace, then install the
plugin:

```shell
/plugin marketplace add kubb-labs/kubb
/plugin install kubb@kubb
```

The commands run `npx kubb`, so install Kubb yourself, in the project or globally:

```shell
npm install -D kubb@beta
```

A `SessionStart` hook checks for `kubb` when a session starts and warns you when it is missing, so
you can install it before running a command. It never installs anything for you.

`kubb init` installs the `@kubb/plugin-*` packages you select. Add `@kubb/adapter-oas` if you
want `kubb validate`.

## Commands

The commands mirror the Kubb CLI and are namespaced under `kubb:`.

| Command | What it does |
| --- | --- |
| `/kubb:init [input] [output] [plugins]` | Scaffold `kubb.config.ts` and install plugins with `kubb init`. |
| `/kubb:generate [input]` | Run `kubb generate` and report what changed. |
| `/kubb:validate <spec>` | Validate an OpenAPI or Swagger spec with `kubb validate`. |

A typical first run:

```text
/kubb:validate ./petStore.yaml
/kubb:init ./petStore.yaml ./src/gen plugin-ts,plugin-zod,plugin-react-query
/kubb:generate
```

## Skill and agent

The plugin ships a `config` skill that teaches Claude how to author a `kubb.config.ts` and pick
the right `@kubb/plugin-*` packages. See [Skills](/docs/5.x/ai/skills) for what it covers.

The `kubb-expert` agent handles "add Kubb to my project" from start to finish. It validates the
spec, chooses plugins, scaffolds the config, and runs generation.

## Conversational generation

The plugin also wires in the Kubb MCP server (`kubb mcp`). When you would rather describe what
you want than type a command, Claude calls the server directly. See [MCP](/docs/5.x/ai/mcp) for
the server and client setup.

## See also

- [Skills](/docs/5.x/ai/skills): the Kubb AI coding skills
- [MCP](/docs/5.x/ai/mcp): connect AI editors directly to Kubb's MCP server
- [Claude MCP guide](/docs/5.x/guides/claude-mcp-plugin): generate an MCP server from your spec
