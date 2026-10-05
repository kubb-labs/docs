---
layout: doc
title: Connect a project to Studio
description: Connect a local Kubb project to Studio, review generated files, and keep an agent running in the background.
outline: [2, 3]
order: 2
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

With a CLI or Docker agent, generation runs in your environment. Studio receives plugin settings, progress, and generated file paths. A local spec is not uploaded. Reading generated file contents or changing local files requires the agent's permission.

## Review and save generated files

To view file contents and diffs, then write generated files to disk, connect with:

```shell [Terminal]
kubb studio --allow-read --allow-write
```

With no permissions granted, generation uses memory and Studio sees file paths and progress. It does not write files or edit your config. The CLI remembers permission answers per project.

Add `--allow-config-edit` to save plugin changes to `kubb.config.ts`. Add `--allow-exec` to run the configured formatter, linter, and `output.postGenerate` commands. See the [command reference](/docs/5.x/reference/commands/studio#options) for all permission flags.

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

Stop the worker before opening a foreground connection. Restart it after a crash or reboot. If status reports `authentication required`, run `kubb studio login`, then start again. See [Background connection](/docs/5.x/reference/commands/studio#background-connection) for worker states, logs, and restart behavior.

In CI or without a TTY, pass an existing `KUBB_AGENT_TOKEN` and the permission flags the run needs. Headless runs do not prompt.

## Snapshot from CI

Follow [Publish snapshots from CI](/docs/5.x/how-to/integrations/ci) to produce installable packages and compare generated-file changes on pull or merge requests. Snapshot generation uses an organization CI API key. Installation uses a separate `registry` API key.

## See also

- [`kubb studio` command](/docs/5.x/reference/commands/studio): actions, flags, environment variables, and snapshot results
- [Configuration](/docs/5.x/reference/configuration): the config a connected project uses
