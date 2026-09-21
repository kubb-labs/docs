# AGENTS.md

kubb-docs is the component-free content repository for the Kubb documentation site. It holds hand-written markdown pages for plugins, adapters, parsers, guides, blog posts, and snippets — consumed by the platform fetch pipeline and rendered on [kubb.dev](https://kubb.dev).

## High-level architecture

This is a content-only repository:
- No npm packages, no TypeScript, no tests
- All files are markdown (`.md`) or code snippet files
- The platform repo ([kubb-labs/platform](https://github.com/kubb-labs/platform)) pulls content from this repo via `apps/kubb.dev/scripts/fetchRepos.ts` and renders it with VitePress

## Repository layout

```
docs/
├── docs/5.x/**            # Hand-written guide and reference pages
├── plugins/<id>/          # One folder per plugin: index.md plus optional guide/recipes/reference subpages
├── adapters/<id>/         # One folder per adapter: index.md plus optional subpages
├── parsers/<id>/          # One folder per parser: index.md plus optional subpages
├── blog/*.md              # Blog posts
├── snippets/**            # Code snippets included via <!--@include: ../snippets/...-->
├── CONTRIBUTING.md        # Contributing guide
└── README.md              # Overview and authoring reference
```

## Content rules

Plugin, adapter, and parser pages mirror those in the platform repo at `apps/kubb.dev/`. When a plugin's options change in [kubb-labs/kubb](https://github.com/kubb-labs/kubb) or [kubb-labs/plugins](https://github.com/kubb-labs/plugins), update the matching page here in the same PR.

Do NOT edit:
- `docs/5.x/changelog.md` — auto-generated from the core repo by the platform pipeline

## Token optimized CLI (rtk)

`rtk` is a CLI proxy that filters and compresses command output to cut token usage. Prefix shell commands with it so output stays small:

```bash
rtk git status
rtk git log -10
```

## How agents read this repo

`AGENTS.md` is the canonical instruction file. Local skills live in `.agents/skills/` (open
`SKILL.md` format, cross-provider). Shared skills, convention rules, `/create-pr`,
`/create-changeset`, `/create-branch`, `/create-issue`, the `code-reviewer` subagent, and the
`house` output style come from the `agents` plugin
([stijnvanhulle/agents](https://github.com/stijnvanhulle/agents)). Claude Code loads it from
this repo's `.claude/settings.json`. Install `agents@stijnvanhulle` for Cursor and Codex.

<skills>

## Skills

</skills>
