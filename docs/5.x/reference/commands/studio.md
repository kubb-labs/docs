---
layout: doc
title: kubb studio
description: The studio command connects a project to Kubb Studio, so you can trigger generation from the browser while Kubb keeps running on your own machine.
outline: [2, 3]
---

# `kubb studio`

Run `kubb studio` to connect a project to [Kubb Studio](https://kubb.studio). Kubb runs on your machine, reads the config and spec from disk, and streams progress and the list of generated files to the browser over a WebSocket. File contents follow only with `--allow-read`.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

```terminal
command: kubb studio
output:
  - ✘ read generated files
  - ✘ write generated files
  - ✘ edit kubb.config.ts
  - ✘ use a Studio spec
  - ✘ run formatter, linter, postGenerate
```

## Usage

Connect the current project. If the project is not approved yet, Studio asks you to approve it before the session starts.

```shell [Terminal]
kubb studio
```

## Actions

The positional argument selects the action. It defaults to `connect`.

| Action     | Description                                                             |
| ---------- | ----------------------------------------------------------------------- |
| `connect`  | Connect, then hold a session open and generate on request.              |
| `login`    | Connect this machine without opening a session.                         |
| `logout`   | Disconnect this machine from Studio.                                    |
| `status`   | Show what this machine is connected as, plus the permissions saved for it. |
| `snapshot` | Generate and publish a snapshot from a script, then exit. See [Snapshot from CI](/docs/5.x/guide/integrations/studio#snapshot-from-ci). |

```terminal
command: kubb studio status
output:
  - Paired with https://kubb.studio as brave-otter
```

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                              | `https://kubb.studio` | Base URL of the Studio instance to connect with.                                   |
| `--allow-read`                             | `false`               | Read the source of files a generation produced. Asked once per project when omitted. |
| `--allow-write`                            | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allow-config-edit`                      | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allow-input`                            | `false`               | Generate from a spec Studio sends instead of the one on disk. Asked once per project. |
| `--allow-exec`                             | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser.                                        |
| `--log-level=<silent\|info\|verbose>`, `-l`| `info`                | Set the verbosity.                                                                 |
| `--token=<key>`                            |                       | `snapshot` only: organization CI API key. Defaults to `KUBB_TOKEN`.                |
| `--id=<id>`                                |                       | `snapshot` only: stable identity for the CI agent. Auto-detected on GitHub Actions, GitLab CI, Bitbucket Pipelines and CircleCI. |
| `--name=<name>`                            |                       | `snapshot` only: package name for the tarball. Defaults to the name in `package.json`. |
| `--package-version=<version>`              |                       | `snapshot` only: package version for the tarball. Defaults to the version in `package.json`. |
| `--timeout=<seconds>`                      | `600`                 | `snapshot` only: seconds to wait for the job to finish, capped at `3600`.          |
| `--json`                                   | `false`               | `snapshot` only: print the result as one JSON object instead of a summary.         |

Approval is per Studio instance, so pointing `--url` at a different instance asks for approval again. Without `--allow-read`, a session still runs a generation and reports which files it produced, but Studio shows no contents for them. Without a permission flag, the CLI asks a yes/no question for each permission and remembers the answers per project directory. It does not ask questions in CI or without a TTY, so unattended runs use only the permissions passed on the command line.

## Environment variables

| Variable           | Description                                                                        |
| ------------------ | ---------------------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory the CLI keeps its Studio state in. Defaults to `~/.kubb`.                |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of approving this machine.            |
| `KUBB_TOKEN`       | `snapshot` only: organization CI API key. Same as `--token`.                       |

## Examples

```shell [Terminal]
kubb studio                              # connect, granting nothing
kubb studio --allow-read                 # show generated files in the browser
kubb studio --allow-write --allow-exec   # write files, run the formatter and linter
kubb studio login                        # connect without opening a session
kubb studio logout                       # disconnect this machine
kubb studio --url http://localhost:3000  # self-hosted Studio
kubb studio snapshot                     # generate and publish a snapshot from CI
kubb studio snapshot --json              # print the snapshot as one JSON object
```

## See also

- [Kubb Studio guide](/docs/5.x/guide/integrations/studio): connect a project, run headless, and self-host
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
