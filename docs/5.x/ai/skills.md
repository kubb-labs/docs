---
layout: doc
title: Skills - AI
description: Kubb ships AI coding skills in the open SKILL.md format so assistants like Claude know how to configure Kubb and run code generation.
outline: [2, 3]
---

# Skills

A skill is a short instruction file in the open `SKILL.md` format that teaches an AI assistant
how to do one thing well. Kubb ships skills so assistants write correct configuration instead of
guessing at an API that changed between major versions.

> [!IMPORTANT]
> The skills ship in the Kubb Claude Code plugin and target Kubb v5 or higher.

## Install

The fastest way to install the Kubb skills is the [`skills` CLI](https://www.skills.sh). Run it
from your project root and it auto-detects your installed agents, including Claude Code, Cursor,
Codex, Windsurf and Cline:

```shell
npx skills add kubb-labs/kubb
```

Pick a specific skill instead of the full set with the `--skill` flag:

```shell
npx skills add kubb-labs/kubb --skill config
```

Pass `-g` to install user-wide instead of per-project, and `-y` to skip the interactive picker:

```shell
npx skills add kubb-labs/kubb -g -y
```

Claude Code users can also install the skills through the plugin marketplace, which adds the
slash commands and agent at the same time:

```shell
/plugin marketplace add kubb-labs/kubb
/plugin install kubb@kubb
```

See the [Claude Code plugin page](/docs/5.x/ai/claude) for what the plugin adds on top of the
skills.

## config

The `config` skill covers how to author a `kubb.config.ts` and pick the right `@kubb/plugin-*`
packages for the output you want. It encodes the rules that trip up models trained on older
releases, such as dropping `pluginOas()` now that the OpenAPI adapter is applied automatically.

It teaches an assistant to:

- write a `kubb.config.ts` with `input`, `output` and a `plugins` array
- map a request such as "typed React Query hooks" or "Zod schemas" to the matching plugin package
- run the `kubb` CLI to validate a spec, scaffold a config, and generate

## Where skills run

The skills ship inside the [Kubb Claude Code plugin](/docs/5.x/ai/claude). Because they are plain
`SKILL.md` files, any assistant that reads that format can use the same content.

## See also

- [Claude](/docs/5.x/ai/claude): the Kubb Claude Code plugin with commands, the skill, and an agent
- [MCP](/docs/5.x/ai/mcp): connect AI editors directly to Kubb's MCP server
- [LLMS.txt](/docs/5.x/ai/llmstxt): machine-readable documentation index for LLMs
