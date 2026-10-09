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
- `docs/5.x/changelog.md`, auto-synced from kubb-labs/kubb by `.github/workflows/sync-changelog.yml` after each release. To update manually, trigger that workflow with `workflow_dispatch`.

### Sidebar

The `docs/5.x` sidebar is built from the files in this repository. A page shows up when its frontmatter sets `order`, its position among the pages in the same folder. Add `navigation.title` when the sidebar label should differ from the page `title`:

```yaml
---
title: Basic Usage
order: 3
navigation:
  title: Getting started
---
```

A folder gets its title, icon and position from a `.navigation.yml` file inside it, such as `title: Guide`, `icon: i-iconoir-book-stack` and `order: 2`. Pages and folders without `order`, like the changelog, stay out of the sidebar. A page that has a folder of the same name (`reference/kit.md` and `reference/kit/`) becomes the group and gets an "Overview" link to itself.

## Development workflow

This repo contains only content: no build step, no npm install, no test suite.

1. Fork and clone this repo.
2. Create a branch from `main`.
3. Edit or add markdown files.
4. Open a PR against `main` and describe what changed and why.

## Writing guidelines

- Write in active voice, present tense.
- Keep paragraphs short, 2 to 3 sentences.
- Explain before showing code.
- On plugin, adapter, and parser overview pages, use a short introduction and bullets for key behavior and dependencies. Keep configuration details on the options page and preserve examples and requirements. Do not add a "Documentation" card group: the sidebar already lists the guides, recipes, and options page from the frontmatter.
- Import `defineConfig` from `kubb/config` in every example.
- Put each page in one Diátaxis quadrant (tutorial, how-to, reference, explanation) and link to the owner page instead of repeating its content. The `snippets/` folder holds text that several pages include.
- Keep each extension overview within an estimated five-minute read: at most 1,000 words at 200 words per minute, counting examples and excluding frontmatter. Move longer explanations to guides or reference pages.

Pages render with Nuxt Content and Nuxt UI's Markdown components. Reuse the same elements for the same purpose:

| Content | Element | Authoring rule |
| --- | --- | --- |
| Comparisons and tabular reference data | Markdown table | Keep related values in columns. Escape `\|` in types. |
| Plugin, adapter, and parser option overviews | Markdown table | Start with an "Options overview" table with "Option", "Purpose", and "Default" columns. Include nested settings, use full option paths, and link each row to its detail heading. Rows for the shared generator options (`output`, `group`, `include`, `exclude`, `override`, `resolver`, `macros`) link to `/docs/5.x/reference/plugin-options#<option>` and carry only the plugin's default. Follow the table with "Option details" holding plugin-specific options only, and retain existing heading anchors. |
| Plugin, adapter, and parser option metadata | Markdown table | Under each detail heading, list the type and whether the option is required. Include a default row when one exists. Keep long types out of the overview and escape `\|` in table cells. Preserve usage examples and generated output below the metadata. |
| Accepted enum values | `::field-group` and `:::field` | Give each accepted value its own field, using the literal value as `name`. Explain its behavior, default status, examples, and constraints in the body. Use fields instead of value comparison tables or bullet lists. Keep option metadata and the compact overview as tables. |
| Individual option metadata on other reference pages | `::field-group` and `:::field` | Set `name` and `type`, and include any default in the body. Under a detail heading, set only `type` so the option name is not repeated. Add `required` only for required options. |
| Background information | `> [!NOTE]` | Use for supplementary context. |
| Recommendations | `> [!TIP]` | Use for optional improvements and useful shortcuts. |
| Requirements | `> [!IMPORTANT]` | State what the reader must do. |
| Potential problems | `> [!WARNING]` | Explain the consequence and how to avoid it. |
| Destructive actions | `> [!CAUTION]` | Explain what the action removes or changes. |
| Linked context | `::callout` | Set `to`, `icon`, and `color` when the whole callout links to another page. |
| Sequential instructions | `::steps{level="2"}` | Use an H2 for each step and keep existing anchors with `{#id}`. |
| Related guides and next steps | `::card-group` and `:::card` | Set `title` and `to`. Add a short description in the body when the title alone does not say what the page covers. |
| Alternative code examples | `::code-group` | Label every fence. Use `sync="package-manager"` for package manager alternatives. |
| Alternative workflows | `::tabs` and `:::tabs-item` | Give each item a `label`. Keep required instructions outside the tabs. |
| Generated directory structures | `::file-tree` | Supply the `tree` array as YAML component props, with `name`, `type`, and optional `children`. |
| Examples spanning multiple files | `::code-tree` | Label code fences with their file paths. |
| Optional long code examples | `::code-collapse` | Set a descriptive `name`. Keep setup and required examples visible. |
| Optional explanations | `::collapsible` | Set a descriptive `name`. Keep requirements and warnings visible. |
| Frequently asked questions | `::accordion` and `:::accordion-item` | Give each item a `label` and preserve linked heading anchors. |
| A rendered example and its source | `::code-preview` | Put the example in the default slot and its source under `#code`. |
| Copyable AI instructions | `::prompt` | Supply a `description` and put the copied text in the body. The body is not displayed, so keep any prompt readers need to inspect in a visible code block. |
| Short status labels | `:badge[Label]` | Use a label readers need to interpret the content. |
| Keyboard shortcuts | `:kbd[Enter]` | Use for keyboard keys rather than commands. |
| Icons beside labels | `:icon{name="i-iconoir-code"}` | Keep a readable text label beside the icon. |
| File type icons | `:code-icon{filename="kubb.config.ts"}` | Code block tabs already infer these icons from their file labels. |

GitHub alerts render as callouts on kubb.dev and also work in repository-only Markdown such as READMEs and ADRs. Keep those files in GitHub-compatible syntax. MDC components belong in site pages, their included snippets, and the Studio docs in the platform repository.

Close a component with the same number of colons used to open it. Use one more colon for a nested component, including code groups and file trees inside steps:

````md
::steps{level="2"}

## Install the package

:::code-group{sync="package-manager"}

```shell [pnpm]
pnpm add -D kubb
```

```shell [npm]
npm install --save-dev kubb
```

:::

::
````

The site also registers its existing diagrams, `::terminal`, and `::studio-cta`. Reuse them with their current props when the content calls for them.

See `.agents/skills/documentation/SKILL.md` for the full writing guide, and `.claude/rules/` for
the USA English and humanizer conventions.

## Updating plugin documentation

Plugin options are the source of truth in [kubb-labs/plugins](https://github.com/kubb-labs/plugins). When a plugin's options change there, update the matching page under `plugins/` here in the same release cycle.

A documented option must match the `Options` type in the plugin's `src/types.ts` and be honored in `src/plugin.ts`. Keep documented defaults in step with the destructuring defaults in `plugin.ts`.

## Opening a pull request

1. Keep changes focused, one topic per PR.
2. Use [Conventional Commits](https://www.conventionalcommits.org/): `docs:`, `fix:`, `feat:`.
3. Push your branch and open a PR against `main`.
