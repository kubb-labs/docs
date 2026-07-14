# Contributing to Kubb docs

This repository holds the hand-written content for [kubb.dev](https://kubb.dev). Contributions are welcome.

- Found a mistake or missing information? [Open an issue](https://github.com/kubb-labs/docs/issues/new) or submit a PR.
- Need help? Ask the community on [Discord](https://discord.gg/4dQjA6vrWX).

Please read our [Code of Conduct](https://github.com/kubb-labs/kubb/blob/main/CODE_OF_CONDUCT.md) before participating.

## What lives here

```
docs/
├── docs/5.x/**            # Guides, concepts, API reference, integrations
├── plugins/<id>/index.md  # One folder per plugin (index.md plus optional guide/recipes/reference/example subpages)
├── adapters/<id>/index.md # One folder per adapter (index.md plus optional reference subpages)
├── parsers/<id>/index.md  # One folder per parser (index.md plus optional reference subpages)
├── blog/*.md              # Blog posts
└── snippets/**            # Code snippets included via <<< @/snippets/...
```

Each plugin, adapter, and parser is a folder with an `index.md` page, plus optional `guide/`, `recipes/`, `reference/`, and `example.md` subpages. The `index.md` frontmatter carries the registry metadata (`id`, `kind`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, `docsPath`, `featured`, `icon`, `maintainers`, `compatibility`, `tags`, `dependencies`, `resources`, `example`, `guides`, `recipes`) that the kubb.dev fetch pipeline turns into the plugin, adapter, and parser cards and detail headers. The `kind` field is `plugin`, `adapter`, or `parser`, and `id` matches the folder name. The pipeline validates the frontmatter against `apps/kubb.dev/public/schemas/extension.json` in kubb-labs/platform, which requires `id`, `name`, `description`, `category`, `type`, `npmPackage`, `repo`, and `docsPath`.

### Live examples

A live example is a page at `plugins/<id>/example.md` that embeds a CodeSandbox iframe. Set `example: true` in the `index.md` frontmatter and kubb.dev adds a "Live example" link to the sidebar:

```yaml
example: true
```

Write the page itself as plain HTML. VitePress compiles markdown into a Vue template, so `:style` bindings work the same as anywhere else in the site:

```md
# Live example

<iframe
  src="https://codesandbox.io/embed/github/kubb-labs/plugins/tree/main/examples/react-query?fontsize=14&module=%2Fkubb.config.ts&theme=dark&view=editor"
  :style="{
    width: '100%',
    height: '700px',
    border: 0,
    borderRadius: '4px',
    overflow: 'hidden'
  }"
  title="React Query"
  allow="accelerometer; ambient-light-sensor; camera; encrypted-media; geolocation; gyroscope; hid; microphone; midi; payment; usb; vr; xr-spatial-tracking"
  sandbox="allow-forms allow-modals allow-popups allow-presentation allow-same-origin allow-scripts"
/>
```

Use the `/embed/github/...` form of the CodeSandbox URL, not a `/p/` or `/s/` share link, and point `module` at the file the embed should open.

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
