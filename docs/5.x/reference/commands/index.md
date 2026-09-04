---
layout: doc
title: Commands
description: Reference for every command and flag exposed by the kubb CLI including init, generate, validate, mcp and studio.
outline: [2, 3]
---

# Commands

The `kubb` CLI is the main way to run Kubb. It reads your [configuration](/docs/5.x/reference/configuration) and runs the generation pipeline. It also scaffolds projects, validates specs, starts a Model Context Protocol server for LLM clients, and connects a project to Kubb Studio.

## Usage

```text [Terminal]
USAGE kubb [COMMAND] [OPTIONS]

COMMANDS
  init                Initialize a new Kubb project with interactive setup
  generate [input]    Generate files based on a 'kubb.config.ts' file (default)
  validate            Validate a Swagger/OpenAPI file
  mcp                 Start the MCP server so an MCP client can interact with the LLM
  studio [action]     Connect this project to Kubb Studio and generate from the browser

Use kubb <command> --help for more information about a command.
```

Run `kubb` with no command and it runs `kubb generate`.

## Available commands

| Command                       | Description                                                       |
| ----------------------------- | ----------------------------------------------------------------- |
| [`kubb init`](./init)         | Scaffold a new Kubb project with an interactive wizard.           |
| [`kubb generate`](./generate) | Run the code-generation pipeline from your `kubb.config.ts`.      |
| [`kubb validate`](./validate) | Validate a Swagger/OpenAPI document without running the pipeline. |
| [`kubb mcp`](./mcp)           | Start a Model Context Protocol server for LLM clients.            |
| [`kubb studio`](./studio)     | Connect the project to Kubb Studio and generate from the browser. |

## Environment variables

The CLI reads these shared environment variables.

| Variable                 | Type      | Used by  | Description                                                                     |
| ------------------------ | --------- | -------- | --------------------------------------------------------------------------------- |
| `KUBB_DISABLE_TELEMETRY` | `boolean` | all      | Turn off anonymous usage telemetry. Set it to `1` or `true`.                    |
| `DO_NOT_TRACK`           | `boolean` | all      | Standard opt-out convention. Set it to `1` or `true`.                           |
| `KUBB_HOME`              | `string`  | `studio` | Directory for the credentials, machine secret, and session registry. Defaults to `~/.kubb`. |
| `KUBB_AGENT_TOKEN`       | `string`  | `studio` | Connect with an existing agent token instead of pairing interactively.          |
