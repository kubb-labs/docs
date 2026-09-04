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

Tuning a Kubb config is a slow loop. You change one plugin option, run `kubb generate`, open the output folder, decide it was wrong, and start over. The feedback lives in your terminal and your file tree, which is a fine place for it, but not a fast one.

[Kubb Studio](https://kubb.studio) puts that loop in a browser tab. You pick plugin options in a form, hit generate, and watch files appear as they are written. What you do not do is upload anything.

> [!WARNING]
> Studio is under active development. Expect breaking changes while it settles.

## Your code never leaves your machine

Every hosted code generator has the same problem: to generate from your spec, it needs your spec. For a public Petstore that is fine. For the internal API that describes your billing system, it is a non-starter at most companies, and no amount of encryption-at-rest copy fixes the org chart.

Studio splits the two halves. The browser holds the UI and the session. Your machine holds the code. When you click generate, Studio sends a command over a WebSocket, Kubb runs locally against the files already on disk, and progress events and generated output stream back to the tab.

Nothing is uploaded, so the spec, the config, and the generated files stay where they already were. As a side effect you also get the plugin versions from your own `node_modules` rather than whatever a server happens to have installed, so what you see in the browser is what you would have gotten from `kubb generate`.

## One command to connect

The runtime ships with the CLI, so there is nothing extra to install. Run this from the project root:

```shell
kubb studio
```

The first run pairs the machine. The CLI prints a short code, opens the approval page, and waits while you approve it. That is [RFC 8628 device authorization](https://www.rfc-editor.org/rfc/rfc8628.html), the same flow a TV app uses when you type a code from your couch. Studio mints an agent token, stores only its hash, and the CLI writes the token to `~/.kubb/credentials.json` at mode `0600`.

Pairing happens once per machine. Every later `kubb studio` connects straight away.

## Read-only until you say otherwise

A tab on the internet can now ask your laptop to run code. We took that seriously, so a fresh session can do almost nothing: generation runs in memory and streams to the browser, and not a single file on disk changes.

Four permissions open that up, and the CLI asks about each one separately on the first connect to a project:

| Permission          | What it grants                                                               |
| ------------------- | ------------------------------------------------------------------------------ |
| `--allowWrite`      | Generated files are written to disk instead of only streaming to Studio.     |
| `--allowConfigEdit` | Studio may change plugin options in your `kubb.config.ts`.                   |
| `--allowInput`      | A spec sent by Studio replaces the one on disk for that generation.          |
| `--allowExec`       | The formatter, the linter, and `output.postGenerate` run as child processes. |

Your answers are saved per project directory, so you are asked once and not on every connect. Pass the flag to skip the question.

The rule we cared most about: nothing is ever asked in CI or without a TTY. An unattended run cannot widen its own access, because there is no one there to approve it and a silent default of yes would be the wrong answer.

## Editing config from the browser

With `--allowConfigEdit`, the options you change in Studio are written back to your `kubb.config.ts`. This is an AST patch rather than a regeneration, so it edits the fields you touched and leaves your comments, import order, and formatting alone. The diff you get is the diff you would have written by hand.

That turns the config into something you can actually explore. Try `group.type: 'tag'`, look at the resulting file tree, switch back, all without leaving the tab.

## Running it somewhere other than a laptop

Pairing needs a browser, and a build agent does not have one. Pair once where you can, then hand the token over through the environment:

```shell
KUBB_AGENT_TOKEN=$KUBB_TOKEN kubb studio
```

A token passed this way is used for the session and never written to disk.

For a connection that outlives your terminal, the `kubblabs/kubb-agent` Docker image runs the same runtime with a fixed plugin set. It suits a team that wants one long-lived agent instead of everyone connecting their own checkout.

Self-hosting the Studio instance itself works too. Point the CLI at it with `kubb studio --url http://localhost:3000`. Credentials are stored per instance, so a self-hosted pairing does not replace your token for the hosted one.

If you only want to see what the thing does, there is a shared sandbox agent you can connect to with no local setup at all. Use it for a public spec you do not mind sending, not for your billing API.

## Try it

Studio is live at [kubb.studio](https://kubb.studio). The [guide](/docs/5.x/guide/going-further/studio) walks through connecting a project, and the [`kubb studio` reference](/docs/5.x/reference/commands/studio) lists every action and flag.

Feedback goes to [GitHub](https://github.com/kubb-labs/kubb/issues) or [Discord](https://discord.gg/shfBFeczrm). The permission model in particular is the part we would most like to hear about before it hardens.
