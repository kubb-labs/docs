# kubb-labs/docs

This repository contains the component-free documentation content for [kubb.dev](https://kubb.dev), sourced from [kubb-labs/platform](https://github.com/kubb-labs/platform) under `apps/kubb.dev/`.

All Markdown is plain VitePress-compatible content with no JSX or Vue components. The platform repo's fetch pipeline reads from this repo to populate the docs site.

## Frontmatter

Every page uses a YAML frontmatter block. The following keys are used:

| Key | Description |
| --- | --- |
| `layout` | VitePress layout. Usually `doc`. |
| `title` | Page title shown in the browser tab and site nav. |
| `description` | Short description used for SEO meta tags. |
| `outline` | Heading depth included in the on-page outline (e.g. `2` or `[2, 3]`). |
| `header` | Extension type badge shown in the page header. One of `plugin`, `adapter`, or `parser`. |

Example frontmatter for a plugin page:

```yaml
---
layout: doc
title: Kubb TypeScript Plugin
description: Generate TypeScript types from OpenAPI schemas.
outline: 2
header: plugin
---
```

## Terminal commands

Use a `terminal` code block to render a styled terminal command on the page:

````markdown
```terminal
kubb generate
```
````

## Badges

Inline badges use the `:badge[text]{type=type}` directive syntax:

```markdown
:badge[stable]{type=tip}
:badge[beta]{type=warning}
:badge[deprecated]{type=danger}
```

## Snippets

Code snippets shared across multiple pages live in `snippets/`. Include them with the VitePress import syntax:

```markdown
<<< @/snippets/plugins/plugin-client/kubb.config.ts [kubb.config.ts]
```

The `@` alias resolves to the root of the docs source tree.
