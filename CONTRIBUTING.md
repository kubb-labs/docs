# Contributing to Kubb docs

This repository holds the hand-written content for [kubb.dev](https://kubb.dev). Contributions are welcome.

- Found a mistake or missing information? [Open an issue](https://github.com/kubb-labs/docs/issues/new) or submit a PR.
- Need help? Ask the community on [Discord](https://discord.gg/4dQjA6vrWX).

Please read our [Code of Conduct](https://github.com/kubb-labs/kubb/blob/main/CODE_OF_CONDUCT.md) before participating.

## What lives here

See the repository layout in `AGENTS.md`. Each plugin, adapter, and parser is a folder with an
`index.md` page, plus optional `guide/`, `recipes/`, and `reference/` subpages. The `index.md` frontmatter carries the registry metadata (`id`, `kind`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, `docsPath`, `featured`, `icon`, `maintainers`, `compatibility`, `tags`, `dependencies`, `resources`, `guides`, `recipes`) that the kubb.dev fetch pipeline turns into the plugin, adapter, and parser cards and detail headers. The `kind` field is `plugin`, `adapter`, or `parser`, and `id` matches the folder name. The pipeline validates the frontmatter against `apps/kubb.dev/public/schemas/extension.json` in kubb-labs/platform, which requires `id`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, and `docsPath`.

### Live example

Set `resources.codesandbox` to a CodeSandbox project link and kubb.dev adds a "Live example" link to the Resources block in the sidebar:

```yaml
resources:
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/react-query
```

### Recipes

Recipes are task-focused pages that live under `plugins/<id>/recipes/<recipe-id>.md`. List them in the `index.md` frontmatter and kubb.dev builds a Recipes group in the sidebar. Each entry needs the page `id` (the file name without its extension) and the `title` shown in the sidebar.

```yaml
recipes:
  - id: class-based-sdk
    title: Class-based SDK
```

Guides follow the same shape under `plugins/<id>/guide/<guide-id>.md` with a `guides` array.

Do NOT edit:
- `docs/5.x/changelog.md` — auto-synced from kubb-labs/kubb by `.github/workflows/sync-changelog.yml` after each release. To update manually, trigger that workflow with `workflow_dispatch`.

## Development workflow

This repo contains only content — no build step, no npm install, no test suite.

1. Fork and clone this repo.
2. Create a branch from `main`.
3. Edit or add markdown files.
4. Open a PR against `main` and describe what changed and why.

## Writing guidelines

- Write in active voice, present tense.
- Keep paragraphs short — 2-3 sentences.
- Explain before showing code.

See `.agents/skills/documentation/SKILL.md` for the full writing guide, and `.claude/rules/` for
the USA English and humanizer conventions.

## Updating plugin documentation

Plugin options are the source of truth in [kubb-labs/plugins](https://github.com/kubb-labs/plugins). When a plugin's options change there, update the matching page under `plugins/` here in the same release cycle.

A documented option must match the `Options` type in the plugin's `src/types.ts` and be honored in `src/plugin.ts`. Keep documented defaults in step with the destructuring defaults in `plugin.ts`.

## Opening a pull request

1. Keep changes focused — one topic per PR.
2. Use [Conventional Commits](https://www.conventionalcommits.org/): `docs:`, `fix:`, `feat:`.
3. Push your branch and open a PR against `main`.
