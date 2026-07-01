---
layout: doc
title: Kubb Markdown Parser
description: Emits `.md` and `.markdown` files from the Kubb AST, joining source blocks as plain markdown and prepending YAML frontmatter from a file's meta.
outline: deep
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

`@kubb/parser-md` lets Kubb emit `.md` and `.markdown` files. Register it in the `parsers` array, and any plugin that writes a markdown source has its output serialized for you.

The parser joins a file's source blocks with blank lines to form the body. When `file.meta.frontmatter` is set, it renders those keys as a YAML frontmatter block and prepends it, so you need no separate `yaml` dependency. Pair it with `parserTs` when a generator emits both TypeScript and documentation files side by side. `parserTs` keeps handling `.ts` and `.js`, and `parserMd` claims `.md` and `.markdown`.

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

`@kubb/parser-md` takes no options of its own. To add a YAML frontmatter block to a generated page, set `frontmatter` on a file's `meta` inside a plugin. The parser renders those keys and prepends them to the output. Any serializable object works.

|          |                                   |
| -------: | :-------------------------------- |
|    Type: | `Record<string, unknown> \| null` |

```typescript [Plugin that sets frontmatter]
ast.factory.createFile({
  baseName: 'README.md',
  path: `${config.output.path}/README.md`,
  meta: {
    frontmatter: { title: 'API Reference', layout: 'doc' },
  },
  sources: [...],
})
```

The parser turns that meta into:

```markdown
---
title: API Reference
layout: doc
---
```

You can also call `parserMd.print` directly to build a frontmatter envelope without depending on `yaml`. It accepts objects and markdown strings and joins them with blank lines, so `parserMd.print({ title: 'Pets', layout: 'doc' })` returns `---\ntitle: Pets\nlayout: doc\n---`.

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

```typescript twoslash [Markdown alongside TypeScript]
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
