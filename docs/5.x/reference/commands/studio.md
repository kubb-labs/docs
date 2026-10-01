---
layout: doc
title: kubb studio
description: Command reference for connecting a project to Kubb Studio, managing pairing and permissions, and publishing CI snapshots.
outline: [2, 3]
---

# `kubb studio`

Run `kubb studio` to connect a project to [Kubb Studio](https://kubb.studio). The CLI runs generation on your machine and sends progress and generated file paths to Studio. Grant `--allow-read` to view generated file contents and diffs in the browser.

## Usage

Connect the current project. On the first run, approve the pairing code in Studio. The CLI then asks which permissions to grant for this project.

```shell [Terminal]
kubb studio
```

## Actions

The positional argument selects the action. It defaults to `connect`.

| Action     | Description                                                                                                                             |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `connect`  | Connect, then hold a session open and generate on request.                                                                              |
| `start`    | Resolve pairing and permissions, then keep this project connected in the background.                                                    |
| `stop`     | Stop the background worker and keep its stored pairing.                                                                                 |
| `login`    | Pair this machine without opening a generation session.                                                                                 |
| `logout`   | Stop the background worker and forget this project's stored Studio token.                                                               |
| `status`   | Show the worker state, log path, pairing, and saved permissions.                                                                        |
| `snapshot` | Generate and publish a snapshot from a script, then exit. See [Snapshot from CI](/docs/5.x/guide/integrations/studio#snapshot-from-ci). |

## Background connection

Run these commands from the same project directory:

```shell [Terminal]
kubb studio start --allow-read
kubb studio status
kubb studio stop
```

`start` resolves pairing and permission prompts before detaching. It returns while the worker
connects; `status` reports `starting`, `connected`, `reconnecting`, `authentication required`, or
`stopped`. Only one background worker can own a project. Stop it before using foreground `connect`.

The worker survives terminal closure. Restart it explicitly after a crash or reboot. If its token
is rejected, run `kubb studio login`, then `kubb studio start` again. To change its URL, config, or
permissions, stop it and start it with the new flags.

Credentials, worker state, and a bounded 1 MiB `worker.log` live under
`$KUBB_HOME/projects/<sha256(project-path)>/` (default `KUBB_HOME`: `~/.kubb`). `status` prints the
log path. `stop` waits for active generation cleanup; `logout` stops the worker before removing
credentials. Interrupted jobs are not replayed.

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                              | `https://kubb.studio` | URL for Kubb Studio.                                                               |
| `--allow-read`                             | `false`               | Let Studio read generated file contents. Asked once per project when omitted.     |
| `--allow-write`                            | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allow-config-edit`                      | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allow-exec`                             | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser.                                        |
| `--log-level=<silent\|info\|verbose>`, `-l` | `info`              | Set the verbosity.                                                                 |
| `--token=<key>`                            |                       | `snapshot` only: organization CI API key. Defaults to `KUBB_TOKEN`.                |
| `--id=<id>`                                |                       | `snapshot` only: stable identity for the CI agent. Auto-detected on GitHub Actions, GitLab CI, Bitbucket Pipelines and CircleCI. |
| `--base-id=<id>`                           |                       | `snapshot` only: the `--id` of another CI agent, such as the base branch's, to also compare with. Auto-detected on GitHub pull requests and GitLab merge requests. |
| `--name=<name>`                            |                       | `snapshot` only: package name for the tarball. Defaults to the name in `package.json`. |
| `--package-version=<version>`              |                       | `snapshot` only: package version for the tarball. Defaults to the version in `package.json`. |
| `--timeout=<seconds>`                      | `600`                 | `snapshot` only: seconds to wait for the job to finish, capped at `3600`.          |
| `--json`                                   | `false`               | `snapshot` only: print the result as one JSON object instead of a summary.         |

Without `--allow-read`, a session still generates and reports file paths, but Studio cannot display their contents. The CLI asks about permissions not supplied as flags and remembers answers per project directory. In CI or without a TTY, it does not prompt, so pass the permissions the run needs explicitly.

## Environment variables

| Variable           | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory the CLI keeps its Studio state in. Defaults to `~/.kubb`.     |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of approving this machine. |
| `KUBB_TOKEN`       | `snapshot` only: organization CI API key. Same as `--token`.            |

## Examples

```shell [Terminal]
kubb studio                              # connect and answer permission prompts
kubb studio --allow-read                 # allow Studio to show generated file contents
kubb studio --allow-write --allow-exec   # write files, run the formatter and linter
kubb studio start --allow-read           # keep this project connected after the terminal closes
kubb studio status                       # show the worker state and log path
kubb studio stop                         # stop the worker and keep pairing
kubb studio login                        # pair without opening a session
kubb studio logout                       # forget the stored token
kubb studio snapshot                     # generate and publish a snapshot from CI
kubb studio snapshot --json              # print the snapshot as one JSON object
```

## See also

- [Kubb Studio guide](/docs/5.x/guide/integrations/studio): connect a project and run headless
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
