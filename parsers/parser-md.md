---
layout: doc
title: Kubb Markdown Parser
description: Markdown file parser for Kubb. Joins source blocks as plain
  markdown and renders YAML frontmatter via `parserMd.print`.
outline: 2
kind: parser
id: parser-md
name: Markdown
category: docs
type: official
npmPackage: "@kubb/parser-md"
repo: https://github.com/kubb-labs/kubb
docsPath: /parsers/parser-md
featured: false
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - markdown
  - frontmatter
  - parser
  - docs
  - yaml
resources:
  documentation: https://kubb.dev/parsers/parser-md
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/parser-md/CHANGELOG.md
---

> [!TIP]
> `parserMd.print({ title: 'Pets', layout: 'doc' })` returns `---\ntitle: Pets\nlayout: doc\n---`. Render it from a plugin to inject frontmatter into a generated page without depending on `yaml` directly.

`@kubb/parser-md` lets Kubb emit `.md` and `.markdown` files. Register it alongside `parserTs`, and any plugin that writes a markdown source has its output serialized automatically.

The parser joins source blocks with blank lines. When `file.meta.frontmatter` is set, it prepends the YAML envelope, so you need no separate `yaml` dependency. Pair it with `parserTs` when a generator emits both TypeScript and documentation files side by side.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/parser-md@beta
```

```shell [pnpm]
pnpm add -D @kubb/parser-md@beta
```

```shell [npm]
npm install --save-dev @kubb/parser-md@beta
```

```shell [yarn]
yarn add -D @kubb/parser-md@beta
```

:::

## Frontmatter

The parser takes no options of its own. To add a YAML frontmatter block, set `frontmatter` on a file's `meta` inside a plugin. The parser then prepends it to the output. Any serializable key-value object works.

|           |                                   |
| --------: | :-------------------------------- |
|     Type: | `Record<string, unknown> \| null` |
| Required: | `false`                           |

```typescript [plugin example]
ast.factory.createFile({
  baseName: 'README.md',
  path: `${config.output.path}/README.md`,
  meta: {
    frontmatter: { title: 'API Reference', layout: 'doc' },
  },
  sources: [...],
})
```

## Example

::: code-group

```typescript [Standalone markdown]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserMd } from '@kubb/parser-md'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserMd],
  plugins: [],
})
```

```typescript [Markdown alongside TypeScript]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserMd } from '@kubb/parser-md'
import { parserTs } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs, parserMd],
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-md/CHANGELOG.md)
