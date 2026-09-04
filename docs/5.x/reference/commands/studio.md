---
layout: doc
title: kubb studio
description: The studio command connects a project to Kubb Studio, so you can trigger generation from the browser while Kubb keeps running on your own machine.
outline: [2, 3]
---

# `kubb studio`

Run `kubb studio` to connect this project to [Kubb Studio](https://kubb.studio). Kubb keeps running on your machine. It reads the config and the spec from disk, then streams progress and generated files back to the browser over a WebSocket, so nothing in your project is uploaded.

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

Connect the current project. The first run pairs the machine, and later runs reuse the stored token.

```shell [Terminal]
kubb studio
```

## Actions

The first positional argument picks what the command does. It defaults to `connect`.

| Action    | Description                                                             |
| --------- | ----------------------------------------------------------------------- |
| `connect` | Pair if needed, then hold a session open and generate on request.       |
| `login`   | Pair this machine and store the token without opening a session.        |
| `logout`  | Forget the stored token.                                                |
| `status`  | Show what this machine is paired as, plus the permissions saved for it. |

```terminal
command: kubb studio status
output:
  - Paired with https://kubb.studio as brave-otter
```

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                              | `https://kubb.studio` | Base URL of the Studio instance to pair and connect with.                          |
| `--allowWrite`                             | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allowConfigEdit`                        | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allowInput`                             | `false`               | Generate from a spec Studio sends instead of the one on disk. Asked once per project. |
| `--allowExec`                              | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser while pairing.                           |
| `--logLevel=<silent\|info\|verbose>`, `-l` | `info`                | Set the verbosity.                                                                 |

> [!IMPORTANT]
> Flags are camelCase. `--allow-write` is not recognized, and the CLI ignores it without a warning, so the permission stays off.

## Pairing

The first connect pairs the machine over [RFC 8628](https://www.rfc-editor.org/rfc/rfc8628.html) device authorization. The CLI prints a short code, opens the approval page unless you pass `--no-open`, and waits while you approve it in Studio. Studio mints the token once and stores only its hash, so it can never be read back.

The token lands in `~/.kubb/credentials.json` at mode `0600`. Set `KUBB_HOME` to keep it, the machine secret, and the session registry somewhere else.

Pairing is per Studio instance. Running `kubb studio --url` against a different instance asks you to pair again, and `kubb studio status` says so before you connect.

## Permissions

The connection is read-only. Generated files stay in memory and stream to the browser, and nothing on disk changes until you grant more.

| Permission          | What it grants                                                                     |
| ------------------- | ----------------------------------------------------------------------------------- |
| `--allowWrite`      | Generated files are written to disk instead of only streaming to Studio.           |
| `--allowConfigEdit` | Studio may change plugin options in your `kubb.config.ts`.                         |
| `--allowInput`      | A spec sent by Studio replaces the one on disk for that generation.                |
| `--allowExec`       | The formatter, the linter, and `output.postGenerate` run as child processes.       |

On the first connect to a project the CLI asks a separate yes/no question for each permission that has no flag and no saved answer. Answers are stored per project directory in `~/.kubb/credentials.json`, so later runs skip the questions. A flag always wins over a saved answer.

Nothing is asked in CI or without a TTY. Anything you did not pass a flag for stays off, so an unattended run can never widen its own access.

## Environment variables

| Variable           | Description                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory for the credentials, the machine secret, and the session registry. Defaults to `~/.kubb`. |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of pairing. The token is not written to disk.          |

## Examples

```shell [Terminal]
# Pair on the first run, then connect read-only
kubb studio

# Let Studio write generated files to disk
kubb studio --allowWrite

# Also run the formatter, the linter, and postGenerate
kubb studio --allowWrite --allowExec

# Pair without opening a session
kubb studio login

# Forget the stored token
kubb studio logout

# Point at a self-hosted Studio
kubb studio --url http://localhost:3000
```

## See also

- [Kubb Studio guide](/docs/5.x/guide/going-further/studio): connect a project, run headless, and self-host
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
