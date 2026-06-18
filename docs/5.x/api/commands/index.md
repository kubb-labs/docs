---
layout: doc
title: Commands
description: Reference for every command and flag exposed by the kubb CLI including init, generate, validate and mcp.
outline: [2, 3]
---

# Commands

The `kubb` CLI is the main way to run Kubb. It reads your [configuration](/docs/5.x/reference/configuration) and runs the generation pipeline. It also scaffolds projects, validates specs, and starts a Model Context Protocol server for LLM clients.

## Installation

The CLI ships with the `kubb` package. After [installation](/docs/5.x/getting-started/installation) it is ready to use. To install it on its own:

::: code-group

```shell [bun]
bun add -d @kubb/cli@beta
```

```shell [pnpm]
pnpm add -D @kubb/cli@beta
```

```shell [npm]
npm install --save-dev @kubb/cli@beta
```

```shell [yarn]
yarn add -D @kubb/cli@beta
```

:::

## Usage

```text
USAGE kubb [COMMAND] [OPTIONS]

COMMANDS
  init                Initialize a new Kubb project with interactive setup
  generate [input]    Generate files based on a 'kubb.config.ts' file (default)
  validate            Validate a Swagger/OpenAPI file
  mcp                 Start the MCP server so an MCP client can interact with the LLM

Use kubb <command> --help for more information about a command.
```

Run `kubb` with no command and it runs `kubb generate`. It reads your config and generates code.

## Available commands

| Command                       | Description                                                       |
| ----------------------------- | ----------------------------------------------------------------- |
| [`kubb init`](./init)         | Scaffold a new Kubb project with an interactive wizard.           |
| [`kubb generate`](./generate) | Run the code-generation pipeline from your `kubb.config.ts`.      |
| [`kubb validate`](./validate) | Validate a Swagger/OpenAPI document without running the pipeline. |
| [`kubb mcp`](./mcp)           | Start a Model Context Protocol server for LLM clients.            |

## Environment variables

The CLI reads these shared environment variables.

| Variable                 | Type      | Used by | Description                                                          |
| ------------------------ | --------- | ------- | -------------------------------------------------------------------- |
| `KUBB_DISABLE_TELEMETRY` | `boolean` | all     | Turn off anonymous usage telemetry. Set it to `1` or `true`.         |
| `DO_NOT_TRACK`           | `boolean` | all     | Standard opt-out convention. Set it to `1` or `true`.                |
