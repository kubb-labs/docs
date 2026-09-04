---
layout: doc
title: Kubb Studio
description: Connect a Kubb project to Kubb Studio and generate from the browser while Kubb runs on your own machine. Covers connecting, permissions, headless runs, and self-hosted instances.
outline: [2, 3]
---

# Kubb Studio

[Kubb Studio](https://kubb.studio) is a browser front end for a Kubb project. You edit plugin options, trigger a generation, and watch the output appear, while the generation itself runs on your machine against the files already on disk.

That split is the point. Studio sends a command over a WebSocket, your machine runs Kubb, and progress events and generated files stream back to the browser. Your spec and your source never leave your infrastructure, so a private API stays private.

> [!WARNING]
> This feature is under active development. Use it with caution and expect breaking changes.

> [!NOTE]
> Studio is not a [bundler integration](/docs/5.x/guide/integrations/) you add to a build. It is a session you open from the CLI and close when you are done.

## Connect a project

The Studio runtime ships with the CLI, so a project that already has `kubb` installed needs nothing else.

Run the command from the project root, next to your `kubb.config.ts`.

```shell [Terminal]
kubb studio
```

The first run opens the approval page in Studio and waits for you to approve this machine. Later runs connect straight away.

Once the session is open, the project shows up in Studio and stays there until you stop the command. Check what a machine is connected as with `kubb studio status`, and disconnect it with `kubb studio logout`.

## Choose what Studio may do

A session is read-only. Generated files stream to the browser and nothing on disk changes, which makes the first connect safe to try on a real project.

Four permissions widen that, and each covers one trust boundary.

| Permission          | What it grants                                                               |
| ------------------- | ------------------------------------------------------------------------------ |
| `--allowWrite`      | Generated files are written to disk instead of only streaming to Studio.     |
| `--allowConfigEdit` | Studio may change plugin options in your `kubb.config.ts`.                   |
| `--allowInput`      | A spec sent by Studio replaces the one on disk for that generation.          |
| `--allowExec`       | The formatter, the linter, and `output.postGenerate` run as child processes. |

The CLI asks a yes/no question for each one on the first connect to a project, then remembers the answers per project directory. Pass the flag to skip the question and grant it up front.

```shell [Terminal]
kubb studio --allowWrite --allowExec
```

Grant `--allowConfigEdit` when you want to tune plugin options from the browser and keep the result. Studio patches the matching fields in `kubb.config.ts` and leaves the comments and formatting around them alone.

## Run headless

Approving a machine needs a browser, which a build agent does not have. Connect once on a machine that has one, then hand the agent token to the headless one through `KUBB_AGENT_TOKEN`.

```shell [Terminal]
KUBB_AGENT_TOKEN=$KUBB_TOKEN kubb studio
```

A token passed this way is used for the session and never written to disk. Permissions are not asked for either, because there is no one to answer: anything without an explicit flag stays off. Grant what the run needs on the command line.

> [!TIP]
> Treat the token like any other credential. Keep it in your CI secret store and pass it through the environment, never in a committed file.

## Point at a self-hosted Studio

`--url` picks the instance to connect with. It defaults to `https://kubb.studio`.

```shell [Terminal]
kubb studio --url http://localhost:3000
```

Approval is per instance, so connecting to a self-hosted Studio does not undo the approval for the hosted one. Switching back needs no extra step, and `kubb studio status` tells you when the instance you are pointing at needs approval first.

Set `KUBB_HOME` to move the CLI's Studio state out of `~/.kubb`. This helps when a container has no stable home directory.

## Run an agent as a service

`kubb studio` is the right way to connect while you are working in a project, but the session ends when you close the terminal. The `kubblabs/kubb-agent` Docker image runs the same runtime with a fixed plugin set and stays connected on its own.

Use the image when a team wants one long-lived agent instead of everyone connecting their own checkout. Use `kubb studio` for everything else. See the [image on Docker Hub](https://hub.docker.com/r/kubblabs/kubb-agent) for how to run and configure it.

## See also

- [`kubb studio` command](/docs/5.x/reference/commands/studio): every action, flag, and environment variable
- [Configuration](/docs/5.x/reference/configuration): the `kubb.config.ts` a session reads
- [Integrations](/docs/5.x/guide/integrations/): run generation inside your bundler instead
