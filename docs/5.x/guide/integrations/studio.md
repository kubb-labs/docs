---
layout: doc
title: Kubb Studio
description: Connect a Kubb project to Kubb Studio and generate from the browser while Kubb runs on your own machine. Covers connecting, permissions, headless runs, and self-hosted instances.
outline: [2, 3]
---

# Kubb Studio

[Kubb Studio](https://kubb.studio) is a browser front end for a Kubb project. You edit plugin options, trigger a generation, and watch the output appear, while the generation itself runs on your machine against the files already on disk.

That split is the point. Studio sends a command over a WebSocket, your machine runs Kubb, and progress events and generated files stream back to the browser. Your spec and your source never leave your infrastructure.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

> [!NOTE]
> Studio is not a [bundler integration](/docs/5.x/guide/integrations/) you add to a build. It is a session you open from the CLI and close when you are done.

## Connect a project

The Studio runtime ships with the CLI, so a project that already has `kubb` installed needs nothing else. Run this from the project root, next to your `kubb.config.ts`.

```shell [Terminal]
kubb studio
```

The first run opens the approval page in Studio and waits for you to approve this machine. Later runs connect straight away. Once the session is open, the project shows up in Studio and stays there until you stop the command. Check what a machine is connected as with `kubb studio status`, and disconnect it with `kubb studio logout`.

## Choose what Studio may do

A session is read-only by default. Generated files stream to the browser and nothing on disk changes, which makes the first connect safe to try on a real project.

Four permissions widen that, and the CLI asks about each one on the first connect to a project, then remembers your answer.

| Permission          | What it grants                                                               |
| -------------------- | ----------------------------------------------------------------------------- |
| `--allowWrite`      | Generated files are written to disk instead of only streaming to Studio.     |
| `--allowConfigEdit` | Studio may change plugin options in your `kubb.config.ts`.                   |
| `--allowInput`      | A spec sent by Studio replaces the one on disk for that generation.          |
| `--allowExec`       | The formatter, the linter, and `output.postGenerate` run as child processes. |

```shell [Terminal]
kubb studio --allowWrite --allowExec
```

Grant `--allowConfigEdit` when you want to tune plugin options from the browser and keep the result. Studio patches the matching fields in `kubb.config.ts` and leaves the comments and formatting around them alone.

## Run headless or self-hosted

`kubb studio` also runs on a build agent, with the agent token passed through `KUBB_AGENT_TOKEN` instead of an interactive approval:

```shell [Terminal]
KUBB_AGENT_TOKEN=$KUBB_TOKEN kubb studio
```

Nothing is asked without a TTY, so grant what the run needs with flags on the command line. Point at a self-hosted instance with `--url`, and set `KUBB_HOME` to move the CLI's Studio state out of `~/.kubb`.

For a connection that outlives your terminal, the [`kubblabs/kubb-agent` Docker image](https://hub.docker.com/r/kubblabs/kubb-agent) runs the same runtime and stays connected on its own. Use it when a team wants one shared agent instead of everyone connecting their own checkout.

## See also

- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` a session reads
- [Integrations](/docs/5.x/guide/integrations/): run generation inside your bundler instead
