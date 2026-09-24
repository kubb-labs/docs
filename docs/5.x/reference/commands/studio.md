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

| Action     | Description                                                             |
| ---------- | ----------------------------------------------------------------------- |
| `connect`  | Connect, then hold a session open and generate on request.              |
| `login`    | Pair this machine without opening a generation session.                 |
| `logout`   | Forget this machine's stored Studio token.                              |
| `status`   | Show the machine's pairing and saved permissions for this project.      |
| `snapshot` | Generate and publish a snapshot from a script, then exit. See [Snapshot from CI](/docs/5.x/guide/integrations/studio#snapshot-from-ci). |

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                               | `https://kubb.studio` | URL for Kubb Studio. |
| `--allow-read`                             | `false`               | Read the source of files a generation produced. Asked once per project when omitted. |
| `--allow-write`                            | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allow-config-edit`                      | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allow-input`                            | `false`               | Generate from a spec Studio sends instead of the one on disk. Asked once per project. |
| `--allow-exec`                             | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser.                                        |
| `--log-level=<silent\|info\|verbose>`, `-l`| `info`                | Set the verbosity.                                                                 |
| `--token=<key>`                            |                       | `snapshot` only: organization CI API key. Defaults to `KUBB_TOKEN`.                |
| `--id=<id>`                                |                       | `snapshot` only: stable identity for the CI agent. Auto-detected on GitHub Actions, GitLab CI, Bitbucket Pipelines and CircleCI. |
| `--base-id=<id>`                           |                       | `snapshot` only: identity of the CI agent to also compare with, such as the one base branch runs use. Auto-detected for pull requests on GitHub Actions, GitLab CI and Bitbucket Pipelines. |
| `--name=<name>`                            |                       | `snapshot` only: package name for the tarball. Defaults to the name in `package.json`. |
| `--package-version=<version>`              |                       | `snapshot` only: package version for the tarball. Defaults to the version in `package.json`. |
| `--timeout=<seconds>`                      | `600`                 | `snapshot` only: seconds to wait for the job to finish, capped at `3600`.          |
| `--json`                                   | `false`               | `snapshot` only: print the result as one JSON object instead of a summary.         |

Without `--allow-read`, a session still generates and reports file paths, but Studio cannot display their contents. The CLI asks about permissions not supplied as flags and remembers answers per project directory. In CI or without a TTY, it does not prompt, so pass the permissions the run needs explicitly.

## Environment variables

| Variable           | Description                                                                        |
| ------------------ | ---------------------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory the CLI keeps its Studio state in. Defaults to `~/.kubb`.                |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of approving this machine.            |
| `KUBB_TOKEN`       | `snapshot` only: organization CI API key. Same as `--token`.                       |

## Examples

```shell [Terminal]
kubb studio                              # connect and answer permission prompts
kubb studio --allow-read                 # allow Studio to show generated file contents
kubb studio --allow-write --allow-exec   # write files, run the formatter and linter
kubb studio login                        # pair without opening a session
kubb studio logout                       # forget the stored token
kubb studio snapshot                     # generate and publish a snapshot from CI
kubb studio snapshot --json              # print the snapshot as one JSON object
```

## See also

- [Kubb Studio guide](/docs/5.x/guide/integrations/studio): connect a project and run headless
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
