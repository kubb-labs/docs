---
layout: doc
title: Commands
description: Reference for every command and flag exposed by the kubb CLI including init, generate, validate and mcp.
outline: [2, 3]
---

# Commands

The `kubb` CLI is your main interface to Kubb. It reads your [configuration](/docs/5.x/reference/configuration) and runs the generation pipeline. It also bootstraps new projects, validates specs, and starts a Model Context Protocol server for LLMs.

## Installation

The CLI comes bundled with the `kubb` package. If you have already completed [installation](/docs/5.x/getting-started/installation), you are ready to go. Otherwise, install the CLI separately:

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

Running `kubb` without arguments is equivalent to `kubb generate`. It reads your config and generates code.

## Available commands

| Command                       | Description                                                       |
| ----------------------------- | ----------------------------------------------------------------- |
| [`kubb init`](./init)         | Bootstrap a new Kubb project with an interactive wizard.          |
| [`kubb generate`](./generate) | Run the code-generation pipeline using your `kubb.config.ts`.     |
| [`kubb validate`](./validate) | Validate a Swagger/OpenAPI document without running the pipeline. |
| [`kubb mcp`](./mcp)           | Start a Model Context Protocol server for LLM clients.            |

## Environment variables

The CLI reads the following shared environment variables.

| Variable                 | Type      | Used by | Description                                                             |
| ------------------------ | --------- | ------- | ----------------------------------------------------------------------- |
| `KUBB_DISABLE_TELEMETRY` | `boolean` | all     | Disable anonymous usage telemetry. Set to `1` or `true` to opt out.     |
| `DO_NOT_TRACK`           | `boolean` | all     | Standard opt-out convention. Set to `1` or `true` to disable telemetry. |
