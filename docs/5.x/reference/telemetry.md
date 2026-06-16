---
layout: doc
title: Telemetry
description: Learn what anonymous usage data Kubb collects, how to opt out, and how the data improves the tool.
outline: [2, 3]
---

# Telemetry

The Kubb CLI collects anonymous usage data so the team can see which plugins and features people actually use, and spot performance bottlenecks.

> [!IMPORTANT]
> Telemetry is enabled by default and can be disabled at any time using the `DO_NOT_TRACK` or `KUBB_DISABLE_TELEMETRY` environment variable.

## What is collected

The following anonymous data is sent after each CLI command:

| Field          | Description                                          | Example                                                                         |
| -------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| `command`      | CLI command that was run                             | `"generate"`, `"validate"`, `"mcp"`                                             |
| `kubbVersion`  | Kubb CLI version                                     | `"5.0.0"`                                                                       |
| `nodeVersion`  | Node.js major version                                | `"22"`                                                                          |
| `platform`     | Operating system                                     | `"linux"`, `"darwin"`, `"win32"`                                                |
| `ci`           | Whether running in CI                                | `true`                                                                          |
| `plugins`      | Plugin names and their options (only for `generate`) | `[{ "name": "@kubb/plugin-ts", "options": { "output": { "path": "types" } } }]` |
| `duration`     | Command execution time in milliseconds               | `1432`                                                                          |
| `filesCreated` | Number of files generated (only for `generate`)      | `47`                                                                            |
| `status`       | Whether the command succeeded or failed              | `"success"`                                                                     |

### Commands that send telemetry

| Command            | Description                                          |
| ------------------ | ---------------------------------------------------- |
| `kubb generate`    | Sent after code generation completes or fails        |
| `kubb validate`    | Sent after OpenAPI validation completes or fails     |
| `kubb mcp`         | Sent after the MCP server starts or fails to start   |

## What is not collected

The following data is never sent:

- OpenAPI specification contents
- File paths or directory structures
- Secrets, API keys, or tokens
- Source code or generated code
- IP addresses or user identifiers

## How to opt out

### `DO_NOT_TRACK` (recommended)

`DO_NOT_TRACK` is a [standard cross-tool opt-out convention](https://consoledonottrack.com/) supported by many developer tools.

```sh
DO_NOT_TRACK=1 kubb generate
```

Add it to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to disable telemetry permanently:

```sh
export DO_NOT_TRACK=1
```

### `KUBB_DISABLE_TELEMETRY`

Kubb-specific opt-out flag:

```sh
KUBB_DISABLE_TELEMETRY=1 kubb generate
```

Or permanently via your shell profile:

```sh
export KUBB_DISABLE_TELEMETRY=1
```

Both environment variables accept `"1"` or `"true"` as values.

## Data transmission

Telemetry is formatted as [OpenTelemetry OTLP](https://opentelemetry.io/docs/languages/sdk-configuration/otlp-exporter/) traces and sent to `https://otlp.kubb.dev/v1/traces` at the end of each command. The request only fires when you're online, times out after 5 seconds, and fails silently if anything goes wrong.
