---
layout: doc
title: kubb studio
description: The studio command connects a project to Kubb Studio, so you can trigger generation from the browser while Kubb keeps running on your own machine.
outline: [2, 3]
---

# `kubb studio`

Run `kubb studio` to connect this project to [Kubb Studio](https://kubb.studio). Kubb keeps running on your machine, reads the config and spec from disk, and streams progress and generated files back to the browser over a WebSocket.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

```terminal
command: kubb studio
output:
  - ✘ write generated files
  - ✘ edit kubb.config.ts
  - ✘ use a Studio spec
  - ✘ run formatter, linter, postGenerate
```

## Usage

Connect the current project. The first run asks you to approve it in Studio, and later runs connect straight away.

```shell [Terminal]
kubb studio
```

## Actions

The first positional argument picks what the command does. It defaults to `connect`.

| Action    | Description                                                             |
| --------- | ----------------------------------------------------------------------- |
| `connect` | Connect, then hold a session open and generate on request.              |
| `login`   | Connect this machine without opening a session.                         |
| `logout`  | Disconnect this machine from Studio.                                    |
| `status`  | Show what this machine is connected as, plus the permissions saved for it. |

```terminal
command: kubb studio status
output:
  - Connected to https://kubb.studio as brave-otter
```

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                              | `https://kubb.studio` | Base URL of the Studio instance to connect with.                                   |
| `--allowWrite`                             | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allowConfigEdit`                        | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allowInput`                             | `false`               | Generate from a spec Studio sends instead of the one on disk. Asked once per project. |
| `--allowExec`                              | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser.                                        |
| `--logLevel=<silent\|info\|verbose>`, `-l` | `info`                | Set the verbosity.                                                                 |

> [!IMPORTANT]
> Flags are camelCase. `--allow-write` is not recognized, and the CLI ignores it without a warning, so the permission stays off.

Approval is per Studio instance, so pointing `--url` at a different instance asks for approval again. The connection is read-only until you grant a permission: on the first connect the CLI asks a yes/no question for each one without a flag, then remembers the answer per project directory. Nothing is asked in CI or without a TTY, so an unattended run stays at whatever access it was given on the command line.

## Environment variables

| Variable           | Description                                                                        |
| ------------------ | ---------------------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory the CLI keeps its Studio state in. Defaults to `~/.kubb`.                |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of approving this machine.            |

## Examples

```shell [Terminal]
kubb studio                              # connect read-only
kubb studio --allowWrite --allowExec     # write files, run the formatter and linter
kubb studio login                        # connect without opening a session
kubb studio logout                       # disconnect this machine
kubb studio --url http://localhost:3000  # self-hosted Studio
```

## See also

- [Kubb Studio guide](/docs/5.x/guide/integrations/studio): connect a project, run headless, and self-host
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
