---
layout: doc
title: Kubb as a Claude Code plugin
description: Install Kubb inside Claude Code and turn an OpenAPI spec into TypeScript types, Zod schemas, clients and React Query hooks without leaving the editor. Ships slash commands, a config skill, an expert agent and the Kubb MCP server.
outline: deep
image: /blog/claude-code-plugin/cover.svg
date: 2026-05-29
---

[← Blog](/blog)

Published: 2026-05-29

![Kubb as a Claude Code plugin](/blog/claude-code-plugin/cover.svg)

# Kubb as a Claude Code plugin

Kubb v5 already ships a built-in MCP server, so AI assistants can drive code generation over HTTP. The next step was to make that setup a single command. Kubb is now a Claude Code plugin. Install it from the marketplace and you get slash commands, a config skill, an expert agent, and the Kubb MCP server, all wired together.

> [!IMPORTANT]
> The plugin requires Kubb v5 or higher. It builds on the v5 CLI and the built-in MCP server.

## Install

Add the repository as a marketplace and install the plugin:

```shell
/plugin marketplace add kubb-labs/kubb
/plugin install kubb@kubb
```

The commands run `npx kubb`, so install Kubb in your project or globally first:

```shell
npm install -D kubb@beta   # in the project
npm install -g kubb@beta   # or globally
```

A `SessionStart` hook checks for `kubb` when a session starts and warns you when it is missing. It never installs anything itself, so nothing runs behind your back.

## Three slash commands

The plugin maps the Kubb CLI to commands you can call from a Claude Code session.

`/kubb:init [input] [output] [plugins]` scaffolds a `kubb.config.ts` and installs the `@kubb/plugin-*` packages you pick. Point it at a spec to start:

```text
/kubb:init ./petstore.yaml
```

Claude asks which outputs you want, writes the config, and installs the packages. Run `/kubb:generate` to re-run codegen whenever the spec changes, and `/kubb:validate <spec>` to check an OpenAPI or Swagger document before you generate from it.

## A skill and an agent

The `config` skill teaches Claude how to write `kubb.config.ts` and which `@kubb/plugin-*` package maps to which output, so the config is correct rather than guessed.

For bigger jobs, the `kubb-expert` agent takes a whole "add Kubb to my project" task from spec to generated code. It picks plugins, scaffolds the config, runs generation, and reports what changed.

## The MCP server, bundled

The plugin wires in the [Kubb MCP server](https://www.npmjs.com/package/@kubb/mcp) (`kubb mcp`) through its `.mcp.json`. When you would rather describe what you want than run a command, the server lets Claude generate code against your config in conversation.

## Try it locally

Before installing from the marketplace, run the plugin straight from a checkout:

```shell
claude --plugin-dir ./tools/claude
```

The plugin is open source and lives in the [kubb-labs/kubb](https://github.com/kubb-labs/kubb) repository. If you hit anything unexpected, open an issue on [GitHub](https://github.com/kubb-labs/kubb/issues).

Kubb is community-driven. If it helps your team, consider [sponsoring the project](https://github.com/sponsors/stijnvanhulle).

👋🏽 [Stijn Van Hulle](https://twitter.com/stijnvanhulle)
