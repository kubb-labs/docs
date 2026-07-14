# Contributing to Kubb docs

This repository holds the hand-written content for [kubb.dev](https://kubb.dev). Contributions are welcome.

- Found a mistake or missing information? [Open an issue](https://github.com/kubb-labs/docs/issues/new) or submit a PR.
- Need help? Ask the community on [Discord](https://discord.gg/4dQjA6vrWX).

Please read our [Code of Conduct](https://github.com/kubb-labs/kubb/blob/main/CODE_OF_CONDUCT.md) before participating.

## What lives here

```
docs/
├── docs/5.x/**            # Guides, concepts, API reference, integrations
├── plugins/<id>/index.md  # One folder per plugin (index.md plus optional guide/reference subpages)
├── adapters/<id>/index.md # One folder per adapter (index.md plus optional reference subpages)
├── parsers/<id>/index.md  # One folder per parser (index.md plus optional reference subpages)
├── blog/*.md              # Blog posts
└── snippets/**            # Code snippets included via <<< @/snippets/...
```

Each plugin, adapter, and parser is a folder with an `index.md` page, plus optional `guide/` and `reference/` subpages. The `index.md` frontmatter carries the registry metadata (`id`, `kind`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, `docsPath`, `featured`, `icon`, `maintainers`, `compatibility`, `tags`, `dependencies`, `resources`, `example`) that the kubb.dev fetch pipeline turns into the plugin, adapter, and parser cards and detail headers. The `kind` field is `plugin`, `adapter`, or `parser`, and `id` matches the folder name. The pipeline validates the frontmatter against `apps/kubb.dev/public/schemas/extension.json` in kubb-labs/platform, which requires `id`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, and `docsPath`.

### Live examples

Set `example` in the frontmatter to a CodeSandbox link and kubb.dev renders it as an inline embed at the bottom of the page. Pass an embed link or a share link — a `/p/github/...` or `/s/github/...` URL is normalized to the embed player, and the embed follows the site's light or dark theme. Point `module` at a file to open it by default:

```yaml
example: https://codesandbox.io/embed/github/kubb-labs/plugins/tree/main/examples/react-query?module=/kubb.config.ts
```

Do NOT edit:
- `docs/5.x/changelog.md` — auto-synced from kubb-labs/kubb by `.github/workflows/sync-changelog.yml` after each release. To update manually, trigger that workflow with `workflow_dispatch`.

## Development workflow

This repo contains only content — no build step, no npm install, no test suite.

1. Fork and clone this repo.
2. Create a branch from `main`.
3. Edit or add markdown files.
4. Open a PR against `main` and describe what changed and why.

## Writing guidelines

- Use USA English (`color`, `license`, `serialize`, `canceled`).
- Write in active voice, present tense.
- Keep paragraphs short — 2-3 sentences.
- Explain before showing code.
- Run a humanizer pass over any prose you write to remove AI patterns.

See `.agents/skills/documentation/SKILL.md` for the full writing guide.

## Updating plugin documentation

Plugin options are the source of truth in [kubb-labs/plugins](https://github.com/kubb-labs/plugins). When a plugin's options change there, update the matching page under `plugins/` here in the same release cycle.

A documented option must match the `Options` type in the plugin's `src/types.ts` and be honored in `src/plugin.ts`. Keep documented defaults in step with the destructuring defaults in `plugin.ts`.

## Opening a pull request

1. Keep changes focused — one topic per PR.
2. Use [Conventional Commits](https://www.conventionalcommits.org/): `docs:`, `fix:`, `feat:`.
3. Push your branch and open a PR against `main`.
