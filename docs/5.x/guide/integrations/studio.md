---
layout: doc
title: Kubb Studio
description: Generate and review OpenAPI clients in Kubb Studio with a local CLI agent, Docker agent, or shared sandbox. Publish installable snapshots from CI.
outline: [2, 3]
---

# Kubb Studio

[Kubb Studio](https://kubb.studio) is a browser workspace for generating and reviewing TypeScript code from an OpenAPI spec. It runs your Kubb plugins to produce types, clients, schemas, and hooks, shows file changes, and can publish installable snapshots from CI.

Choose where generation runs:

| Option | Use it for |
| --- | --- |
| [Shared sandbox](https://kubb.studio) | Try Studio with a spec you provide in the browser, without installing anything. |
| `kubb studio` | Work on a local project with its existing spec, config, and plugin versions. |
| [Docker agent](https://hub.docker.com/r/kubblabs/kubb-agent) | Keep an agent connected on your infrastructure for a team. |

With a CLI or Docker agent, generation runs in your environment. Studio receives plugin settings, progress, and generated file paths. A local spec is not uploaded. Reading generated file contents or changing local files requires the agent's permission. The shared sandbox runs outside your environment, so use it with a spec you are comfortable providing there.

<StudioCTA source="studio-guide" />

## Connect a local project

Run the command from a project with Kubb installed and a `kubb.config.ts`:

```shell [Terminal]
kubb studio
```

The first run opens Studio to approve the machine. After approval, keep the command running and select the connected agent in Studio. Generate from the browser to see progress and the file tree. Grant `--allow-read` to view file contents and diffs.

The CLI asks which permissions to grant for this project and remembers your answers. With no permissions granted, generation uses memory and Studio sees file paths and progress. It does not write generated files or edit your config. For example, to review generated files and write them to disk:

```shell [Terminal]
kubb studio --allow-read --allow-write
```

Use `--allow-config-edit` to save plugin option changes to `kubb.config.ts`. Use `--allow-input` to generate from a spec supplied in Studio instead of the project's spec. Use `--allow-exec` to run the configured formatter, linter, and `output.postGenerate` commands. See the [`kubb studio` reference](/docs/5.x/reference/commands/studio) for all flags and actions.

## Run an agent without a terminal session

For a long-running team connection, run the [Docker agent](https://hub.docker.com/r/kubblabs/kubb-agent). You can also run the CLI without a TTY using an existing agent token:

```shell [Terminal]
KUBB_AGENT_TOKEN=your-agent-token kubb studio --allow-read
```

Headless runs do not ask permission questions. Pass the permissions the run needs as flags. `kubb studio status` shows the current machine's pairing and saved project permissions. `kubb studio logout` forgets its token.

## Snapshot from CI

`kubb studio snapshot` generates an installable package on a CI runner, publishes the tarball to Studio, and exits. It uses an organization CI API key in `KUBB_TOKEN`, not an agent token:

```shell [Terminal]
kubb studio snapshot
```

The command detects GitHub Actions, GitLab CI, Bitbucket Pipelines, and CircleCI. For another CI provider, pass a stable `--id`. Use `--json` when a later step needs the tarball URL:

```shell [Terminal]
kubb studio snapshot --json | jq -r '.url'
```

Follow the [GitHub Actions](./github-actions) or [GitLab CI](./gitlab) guide for a complete workflow. Installing the tarball requires a separate `registry` API key.

## See also

- [`kubb studio` command](/docs/5.x/reference/commands/studio): actions, flags, and environment variables
- [Configuration](/docs/5.x/reference/configuration): the config a connected project uses
