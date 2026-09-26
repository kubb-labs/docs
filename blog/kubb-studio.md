---
layout: doc
title: Introducing Kubb Studio
description: Kubb Studio lets you generate and review OpenAPI clients in the browser with a local agent, Docker agent, or shared sandbox.
outline: deep
image: /blog/kubb-studio/cover.svg
date: 2026-09-04
---

[← Blog](/blog)

Published: 2026-09-04

![Introducing Kubb Studio](/blog/kubb-studio/cover.svg)

# Introducing Kubb Studio

Tuning a Kubb config takes repeated runs. You change a plugin option, run `kubb generate`, and check the output folder.

[Kubb Studio](https://kubb.studio) puts that loop in a browser tab. You change plugin options, generate, and review the resulting files. Connect your project to run Kubb locally, or use the shared sandbox to try it without setup.

## Generation stays where your agent runs

With a connected CLI or Docker agent, Kubb uses the spec and plugin versions in your environment. Studio receives plugin settings, progress, and generated file paths. Your local spec is not uploaded. During an interactive generation, Studio receives generated file contents only when you grant read access. The shared sandbox runs on shared infrastructure and uses a spec you provide in the browser.

## One command to connect

The runtime ships with the CLI, so a project with Kubb installed needs nothing extra:

```shell
kubb studio
```

The first run asks you to approve this machine in Studio. Every later `kubb studio` connects straight away.

## Choose what Studio can access

A session with no permissions granted generates in memory. It sends progress and file paths to Studio but does not change files on disk. The CLI asks about four permissions:

| Permission            | What it grants                                                               |
| --------------------- | ----------------------------------------------------------------------------- |
| `--allow-read`        | Studio can read the source of the files a generation produced.              |
| `--allow-write`       | Generated files are written to disk instead of only streaming to Studio.    |
| `--allow-config-edit` | Studio may change plugin options in your `kubb.config.ts`.                  |
| `--allow-exec`        | The formatter, the linter, and `output.postGenerate` run as child processes. |

The CLI remembers your answers per project. In CI or without a TTY, it does not prompt, so pass the needed permissions as flags.

## Editing config from the browser

With `--allow-config-edit`, Studio can save changed plugin options to `kubb.config.ts`. The edit preserves the surrounding comments and formatting.

## Beyond your laptop

The `kubblabs/kubb-agent` Docker image keeps a team agent connected. In CI, `kubb studio snapshot` publishes an installable package for a pull or merge request. See the [guide](/docs/5.x/guide/integrations/studio) for setup.

## Try it

Studio is live at [kubb.studio](https://kubb.studio). The [guide](/docs/5.x/guide/integrations/studio) walks through connecting a project, and the [`kubb studio` reference](/docs/5.x/reference/commands/studio) lists every action and flag.

Feedback goes to [GitHub](https://github.com/kubb-labs/kubb/issues) or [Discord](https://discord.gg/shfBFeczrm).
