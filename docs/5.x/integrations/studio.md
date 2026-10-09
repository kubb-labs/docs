---
layout: doc
title: Connect a project to Studio
description: Connect a local Kubb project to Studio, review generated files, and keep an agent running in the background.
outline: [2, 3]
order: 1
navigation:
  title: Kubb Studio
  icon: i-iconoir-cube
---

# Connect a project to Studio

Use [Kubb Studio](https://kubb.studio) to generate and review a project's clients, types, schemas, hooks, and mocks from the browser. Start with Kubb installed and a `kubb.config.ts` in your project.

For a quick trial without local setup, use Studio's shared sandbox with a spec you are comfortable providing outside your environment. For a persistent team connection on your infrastructure, use the [Docker agent](https://hub.docker.com/r/kubblabs/kubb-agent).

## Connect your project

Run this command from the project directory:

```shell [Terminal]
kubb studio
```

Approve the machine in the Studio window and answer the permission prompts. Keep the command running, select the connected agent in Studio, and generate to see progress and the file tree.

> [!NOTE]
> With a CLI or Docker agent, generation runs in your environment. Studio receives plugin settings, progress, and generated file paths. A local spec is not uploaded. Reading generated file contents or changing local files requires the agent's permission.

## Review and save generated files

To view file contents and diffs, then write generated files to disk, connect with:

```shell [Terminal]
kubb studio --allow-read --allow-write
```

With no permissions granted, generation uses memory and Studio sees file paths and progress only. The CLI remembers permission answers per project. See [Options](/docs/5.x/reference/commands/studio#options) for `--allow-config-edit`, `--allow-exec`, and the other flags.

## Keep an agent running in the background

Start the connection from your project directory:

```shell [Terminal]
kubb studio start --allow-read
```

Complete pairing and permission prompts if this is the first connection. Check that the worker is connected:

```shell [Terminal]
kubb studio status
```

To end the background connection, run:

```shell [Terminal]
kubb studio stop
```

See [Background connection](/docs/5.x/reference/commands/studio#background-connection) for worker states, logs, and restart behavior.

> [!IMPORTANT]
> Without a TTY the CLI skips the permission prompts, so pass the permission flags the run needs. In CI it does not pair interactively either: provide stored credentials or `KUBB_AGENT_TOKEN`.

## See also

- [Publish snapshots from CI](/docs/5.x/integrations/ci): installable packages and generated-file diffs on pull requests
- [`kubb studio` command](/docs/5.x/reference/commands/studio): actions, flags, environment variables, and snapshot results
