---
layout: doc
title: kubb studio
description: Command reference for connecting a project to Kubb Studio, managing
  pairing and permissions, and publishing CI snapshots.
outline:
  - 2
  - 3
order: 5
navigation:
  title: kubb studio
  icon: i-iconoir-cube
---

# kubb studio

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
| `connect` | Hold a foreground session open and generate on request. |
| `start` | Resolve pairing and permissions, then connect this project in the background. |
| `stop` | Stop the background worker and keep its pairing. |
| `login`    | Pair this machine without opening a generation session.                 |
| `logout` | Stop the background worker and forget this project's stored token. |
| `status` | Show worker state, log path, pairing, and saved permissions. |
| `snapshot` | Generate and publish a snapshot from a script, then exit. See [Publish snapshots from CI](/docs/5.x/integrations/ci). |

## Background connection

Run `start`, `status`, and `stop` from the same project directory. `start` resolves pairing and permission prompts before detaching, then returns while the worker connects.

`status` reports `starting`, `connected`, `reconnecting`, `authentication required`, or `stopped`. Only one worker can own a project. Stop it before using foreground `connect`.

The worker survives terminal closure and retries temporary connection failures. Restart it after a crash or reboot. If its token is rejected, run `kubb studio login`, then `kubb studio start`. To change its URL, config, or permissions, stop it and start with the new flags.

Credentials, worker state, and a bounded 1 MiB `worker.log` live under `$KUBB_HOME/projects/<sha256(project-path)>/`. `KUBB_HOME` defaults to `~/.kubb`. `status` prints the log path. `stop` waits for active generation cleanup. `logout` stops the worker before removing credentials. Interrupted jobs are not replayed.

## Options

| Option                                     | Default               | Description                                                                        |
| ------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`             |                       | Path to a config file, such as `./kubb.staging.ts`.                                |
| `--url=<url>`                               | `https://kubb.studio` | URL for Kubb Studio. |
| `--allow-read`                             | `false`               | Let Studio read generated file contents. Asked once per project when omitted.          |
| `--allow-write`                            | `false`               | Write generated files to disk. Asked once per project when omitted.                |
| `--allow-config-edit`                      | `false`               | Let Studio change plugin options in `kubb.config.ts`. Asked once per project.      |
| `--allow-exec`                             | `false`               | Run the formatter, the linter, and `output.postGenerate`. Asked once per project.  |
| `--no-open`                                |                       | Do not open the approval page in a browser.                                        |
| `--log-level=<silent\|info\|verbose>`, `-l`| `info`                | Set the verbosity.                                                                 |
| `--token=<key>`                            |                       | `snapshot` only: organization CI API key. Defaults to `KUBB_TOKEN`.                |
| `--id=<id>`                                |                       | `snapshot` only: stable identity for the CI agent. Auto-detected on GitHub Actions, GitLab CI, Bitbucket Pipelines and CircleCI. |
| `--base-id=<id>`                           |                       | `snapshot` only: the `--id` of another CI agent, such as the base branch's, to also compare with. Auto-detected on GitHub pull requests and GitLab merge requests. |
| `--name=<name>`                            |                       | `snapshot` only: package name for the tarball. Defaults to the name in `package.json`. |
| `--package-version=<version>`              |                       | `snapshot` only: package version for the tarball. Defaults to the version in `package.json`. |
| `--timeout=<seconds>`                      | `600`                 | `snapshot` only: seconds to wait for the job to finish, capped at `3600`.          |
| `--json`                                   | `false`               | `snapshot` only: print the result as one JSON object instead of a summary.         |

Without `--allow-read`, a session still generates and reports file paths, but Studio cannot display their contents. The CLI asks about permissions not supplied as flags and remembers answers per project directory. Without a TTY it skips the permission prompts, so pass the flags the run needs. In CI it also refuses to pair interactively and needs stored credentials or `KUBB_AGENT_TOKEN`.

## Environment variables

| Variable           | Description                                                                        |
| ------------------ | ---------------------------------------------------------------------------------- |
| `KUBB_HOME`        | Directory the CLI keeps its Studio state in. Defaults to `~/.kubb`.                |
| `KUBB_AGENT_TOKEN` | Connect with an existing agent token instead of approving this machine.            |
| `KUBB_TOKEN`       | `snapshot` only: organization CI API key. Same as `--token`.                       |

## Snapshot output

`--json` prints one JSON object with `id`, `name`, `version`, `integrity`, `url`, `snapshotIdUrl`, `expiresAt`, and `agentUrl`. It also includes `changes` and `branchChanges` when comparisons are available. Installing a snapshot requires a separate `registry` API key.

| JSON field | Compared with |
| --- | --- |
| `changes` | The previous snapshot on the same pull request or branch. |
| `branchChanges` | The latest snapshot of a GitHub pull request's base branch or a GitLab merge request's target branch. Its `baseFound` field distinguishes a branch with no CI agent from one with an agent that has no snapshot of this package yet. |

## CI agent identity

`snapshot` detects GitHub Actions, GitLab CI, Bitbucket Pipelines, and CircleCI. Other providers require a stable `--id`. Use a stable `--id` on the base branch and pass that identity as `--base-id` on pull request runs.

### GitLab CI

The CI agent registers as `gl:<project id>:<merge request iid>`, read from `CI_PROJECT_ID` and `CI_MERGE_REQUEST_IID`, so every pipeline on that merge request reuses one agent. A branch pipeline falls back to `CI_COMMIT_REF_SLUG`, so the default branch has one agent too. Pass `--id` to group runs your own way.

A merge request pipeline also names its target branch's agent, from `CI_MERGE_REQUEST_TARGET_BRANCH_NAME`. The snapshot reports which generated files changed against that branch's latest snapshot in `branchChanges`, and against the merge request's previous pipeline in `changes`. The commit it records is the source branch's head, `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`, when GitLab sets it.

## See also

- [Kubb Studio guide](/docs/5.x/integrations/studio): connect a project and run headless
- [Commands](/docs/5.x/reference/commands/): every command the CLI exposes
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` Studio reads
