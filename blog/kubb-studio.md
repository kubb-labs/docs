---
layout: doc
title: Introducing Kubb Studio
description: Kubb Studio is a browser front end for a Kubb project. You change plugin options and trigger generation from a tab, while Kubb runs on your own machine and your spec stays on disk.
outline: deep
image: /blog/kubb-studio/cover.svg
date: 2026-09-04
---

[← Blog](/blog)

Published: 2026-09-04

![Introducing Kubb Studio](/blog/kubb-studio/cover.svg)

# Introducing Kubb Studio

Tuning a Kubb config is a slow loop. You change one plugin option, run `kubb generate`, open the output folder, decide it was wrong, and start over.

[Kubb Studio](https://kubb.studio) puts that loop in a browser tab. You pick plugin options in a form, hit generate, and watch files appear as they are written. What you do not do is upload anything.

> [!WARNING]
> Studio is under active development. Expect breaking changes while it settles.

## Your code never leaves your machine

To generate from your spec, a hosted generator needs your spec. For a public Petstore that is fine. For the internal API that describes your billing system, it usually is not.

Studio splits the two halves. The browser holds the UI, your machine holds the code. When you click generate, Studio sends a command over a WebSocket, Kubb runs locally against the files already on disk, and progress and output stream back to the tab. Nothing is uploaded, so you get the plugin versions already in your `node_modules`, not whatever a server has installed.

## One command to connect

The runtime ships with the CLI, so there is nothing extra to install:

```shell
kubb studio
```

The first run asks you to approve this machine in Studio. Every later `kubb studio` connects straight away.

## Read-only until you say otherwise

A fresh session can do almost nothing: generation runs in memory and streams to the browser, and not a single file on disk changes. Four flags open that up one at a time:

| Permission          | What it grants                                                               |
| -------------------- | ----------------------------------------------------------------------------- |
| `--allowWrite`      | Generated files are written to disk instead of only streaming to Studio.     |
| `--allowConfigEdit` | Studio may change plugin options in your `kubb.config.ts`.                   |
| `--allowInput`      | A spec sent by Studio replaces the one on disk for that generation.          |
| `--allowExec`       | The formatter, the linter, and `output.postGenerate` run as child processes. |

The CLI asks about each one on the first connect to a project and remembers your answer. Nothing is ever asked in CI or without a TTY: an unattended run stays at whatever access it was explicitly given.

## Editing config from the browser

With `--allowConfigEdit`, the options you change in Studio are written back to your `kubb.config.ts` as an AST patch, not a regeneration, so it touches only the fields you changed and leaves the rest alone. Try `group.type: 'tag'`, look at the resulting file tree, switch back, all without leaving the tab.

## Beyond your laptop

`kubb studio` also runs from CI or a long-lived server, and the `kubblabs/kubb-agent` Docker image runs the same runtime for a team that wants one shared agent. See the [guide](/docs/5.x/guide/integrations/studio) for how.

## Try it

Studio is live at [kubb.studio](https://kubb.studio). The [guide](/docs/5.x/guide/integrations/studio) walks through connecting a project, and the [`kubb studio` reference](/docs/5.x/reference/commands/studio) lists every action and flag.

Feedback goes to [GitHub](https://github.com/kubb-labs/kubb/issues) or [Discord](https://discord.gg/shfBFeczrm). The permission model in particular is the part we would most like to hear about before it hardens.
