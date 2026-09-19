---
layout: doc
title: Kubb Studio
description: Connect a Kubb project to Kubb Studio and generate from the browser while Kubb runs on your own machine. Covers connecting, permissions, headless runs, and agents.
outline: [2, 3]
---

# Kubb Studio

[Kubb Studio](https://kubb.studio) is a browser interface for a Kubb project. You edit plugin options, trigger a generation, and watch its progress while Kubb runs on your machine against the files on disk.

Kubb reports progress and generated file paths to Studio. Your spec stays on your machine. Studio reads source from a generated file only after you grant `--allow-read`.

<StudioCTA source="studio-guide" />

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

> [!NOTE]
> Studio is not a [bundler integration](/docs/5.x/guide/integrations/) you add to a build. It is a session you open from the CLI and close when you are done.

## Connect a project

The Studio runtime ships with the CLI, so a project that already has `kubb` installed needs nothing else. Run this from the project root, next to your `kubb.config.ts`.

```shell [Terminal]
kubb studio
```

When the project is not approved yet, an interactive CLI session with a TTY opens Studio's approval page and waits for confirmation. Once approved, the session connects and the project appears in Studio until you stop the command. Check the connected machine with `kubb studio status`, and disconnect it with `kubb studio logout`.

## Choose what Studio may do

A session is read-only by default. Studio sees generated file paths, but not their source, and nothing on disk changes. It is safe to try on a real project.

The CLI exposes five permissions. An interactive session with a TTY asks about each permission when you first connect a project, then remembers your answers. CI and other headless sessions do not prompt, so pass the permission flags explicitly.

| Permission            | What it grants                                                               |
| --------------------- | ----------------------------------------------------------------------------- |
| `--allow-read`        | Studio can read the source of the files a generation produced.              |
| `--allow-write`       | Generated files are written to disk instead of only streaming to Studio.    |
| `--allow-config-edit` | Studio may change plugin options in your `kubb.config.ts`.                  |
| `--allow-input`       | A spec sent by Studio replaces the one on disk for that generation.         |
| `--allow-exec`        | The formatter, the linter, and `output.postGenerate` run as child processes. |

```shell [Terminal]
kubb studio --allow-read --allow-write --allow-exec
```

Grant `--allow-config-edit` when you want to tune plugin options from the browser and keep the result. Studio patches the matching fields in `kubb.config.ts` and leaves the comments and formatting around them alone.

## Run headless

`kubb studio` also runs on a build agent, with the agent token passed through `KUBB_AGENT_TOKEN` instead of an interactive approval:

```shell [Terminal]
KUBB_AGENT_TOKEN=your-agent-token kubb studio
```

Nothing is asked without a TTY, so grant what the run needs with flags on the command line. `--allow-read` is the one a headless run most often forgets: without it, generated files show up in the tree with no contents. Set `KUBB_HOME` to move the CLI's Studio state out of `~/.kubb`.

Kubb Studio itself is hosted at [kubb.studio](https://kubb.studio) and is not available for self-hosting. The agent that connects your environment to Studio can run wherever you need it: through the CLI, in CI, or with Docker.

For a connection that outlives your terminal, the [`kubblabs/kubb-agent` Docker image](https://hub.docker.com/r/kubblabs/kubb-agent) runs the same runtime and stays connected on its own. Use it when a team wants one shared agent instead of everyone connecting their own checkout.

## Snapshot from CI

`kubb studio snapshot` generates a package and publishes it to Studio in one command, then exits. Use it in GitHub Actions or GitLab CI to hand a reviewer an installable tarball on a pull or merge request. It needs a different credential than `kubb studio`: an organization CI API key, not an agent token.

```shell [Terminal]
KUBB_TOKEN=$KUBB_TOKEN kubb studio snapshot
```

The command detects GitHub Actions, GitLab CI, Bitbucket Pipelines, and CircleCI on its own, and reuses one CI agent per pull or merge request instead of registering a new one on every run. On another CI, pass `--id` with something stable, such as the merge request number.

Use `--json` to read the result in a later step. It prints one JSON object with the tarball URL, the package name and version, and the integrity hash, and nothing else on stdout.

```shell [Terminal]
kubb studio snapshot --json | jq -r '.url'
```

Two providers have a page of their own:

- [GitHub Actions](./github-actions), through [`kubb-labs/action`](https://github.com/kubb-labs/action)
- [GitLab CI](./gitlab), through a `.gitlab-ci.yml` job

> [!NOTE]
> The tarball URL needs a `registry` API key to download, not the `ci` key that created the snapshot. Create one in Studio's settings for whichever system installs the package.

See the [`snapshot` action reference](/docs/5.x/reference/commands/studio#actions) for every flag.

## See also

- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
- [GitHub Actions](./github-actions): publish a snapshot on every pull request
- [GitLab CI](./gitlab): publish a snapshot on every merge request
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` a session reads
- [Integrations](/docs/5.x/guide/integrations/): run generation inside your bundler instead
