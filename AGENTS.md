# AGENTS.md

kubb-docs is the component-free content repository for the Kubb documentation site. It holds hand-written markdown pages for plugins, adapters, parsers, guides, blog posts, and snippets. The platform fetch pipeline consumes them and renders them on [kubb.dev](https://kubb.dev).

## High-level architecture

This is a content-only repository:
- No npm packages, no TypeScript, no tests
- Documentation is written in Markdown, with code examples kept in Markdown pages or snippet files. The repository also includes supporting metadata, licenses, and GitHub workflows.
- The platform repo ([kubb-labs/platform](https://github.com/kubb-labs/platform)) pulls content from this repo via `apps/kubb.dev/scripts/fetchRepos.ts` and renders it with Nuxt Content (MDC syntax)

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

Plugin, adapter, and parser pages live under `plugins/<id>/`, `adapters/<id>/`, and `parsers/<id>/`, each with an `index.md` overview and a `reference/options.md`. Options every generator plugin shares (`output`, `group`, `include`, `exclude`, `override`, `resolver`, `macros`) are documented once in `docs/5.x/reference/plugin-options.md`. A plugin page lists only its own defaults and links there. When a plugin's options change in [kubb-labs/kubb](https://github.com/kubb-labs/kubb) or [kubb-labs/plugins](https://github.com/kubb-labs/plugins), update the matching page here in the same PR.

Each page sits in one [Diátaxis](https://diataxis.fr) quadrant: `docs/5.x/tutorials/` teaches by doing, `docs/5.x/how-to/` and the plugin `guide/` and `recipes/` folders get one task done, `docs/5.x/reference/` and `reference/options.md` state facts, `docs/5.x/explanation/` builds understanding. Keep them apart: no option tables in a how-to, no walkthroughs in a reference.

Do NOT edit:
- `docs/5.x/changelog.md`, auto-generated from the core repo by the platform pipeline

## How agents read this repo

`AGENTS.md` is the canonical instruction file. Local skills live in `.agents/skills/` (open
`SKILL.md` format, cross-provider). Shared skills, convention rules, `/create-pr`,
`/create-changeset`, `/create-branch`, `/create-issue`, the `code-reviewer` subagent, and the
`house` output style come from the `agents` plugin
([stijnvanhulle/agents](https://github.com/stijnvanhulle/agents)). Claude Code loads it from
this repo's `.claude/settings.json`. Install `agents@stijnvanhulle` for Cursor and Codex.
