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
├── plugins/*.md           # Plugin documentation pages
├── adapters/*.md          # Adapter documentation pages
├── parsers/*.md           # Parser documentation pages
├── blog/*.md              # Blog posts
├── snippets/**            # Code snippets included via <<< @/snippets/...
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

`AGENTS.md` is the canonical instruction file. `CLAUDE.md`, `GEMINI.md`, and
`.github/copilot-instructions.md` symlink to it. Skills live in `.agents/skills/` (open
`SKILL.md` format, cross-provider). Always-on conventions live in `.claude/rules/`
(`markdown`, `security`, `usa-english`).

<skills>

## Skills

You have new skills. If any skill might be relevant then you MUST read it.

- [documentation](.agents/skills/documentation/SKILL.md) - Use when writing blog posts or documentation markdown files - provides writing style guide (active voice, present tense), content structure patterns, and SEO optimization. Overrides brevity rules for proper grammar.
- [humanizer](.agents/skills/humanizer/SKILL.md) - Remove AI writing patterns to make documentation sound natural, specific, and human. Covers content patterns, language patterns, style patterns, and communication patterns.
</skills>
