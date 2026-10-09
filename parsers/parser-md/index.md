---
layout: doc
title: Kubb Markdown Parser
description: Emits `.md` and `.markdown` files from the Kubb AST, joining source
  blocks as plain markdown and prepending YAML frontmatter from a file's meta.
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

# @kubb/parser-md

`@kubb/parser-md` emits `.md` and `.markdown` files by joining source blocks with blank lines. It prepends YAML frontmatter from `file.meta.frontmatter`.

The parser takes no options and runs by default alongside `parserTs` and `parserTsx`.

> [!IMPORTANT]
> A custom `parsers` array replaces the default set. Include every parser your plugins need. Unmatched files are written as source text.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/parser-md
```

```shell [pnpm]
pnpm add -D @kubb/parser-md
```

```shell [npm]
npm install --save-dev @kubb/parser-md
```

```shell [yarn]
yarn add -D @kubb/parser-md
```

::

## Dependencies

No plugin dependencies. The parser registers on `defineConfig.parsers`.

## Frontmatter

To add a YAML frontmatter block to a generated page, set `frontmatter` on a file's `meta` inside a plugin. The parser renders those keys and prepends them to the output. Any serializable object works.

::field-group

:::field{name="meta.frontmatter" type="Record<string, unknown> | null"}
YAML frontmatter prepended to the generated Markdown file.
:::

::

::code-group

```typescript [plugin.ts]
import { ast } from 'kubb/kit'

const file = ast.factory.createFile({
  baseName: 'README.md',
  path: './src/gen/README.md',
  meta: {
    frontmatter: { title: 'API Reference', layout: 'doc' },
  },
  sources: [ast.factory.createSource({ nodes: [ast.factory.createText('# API Reference')] })],
})
```

```markdown [README.md]
---
title: API Reference
layout: doc
---
```

::

You can also call `parserMd().print` directly to build a frontmatter envelope. It accepts objects and markdown strings and joins them with blank lines, so `parserMd().print({ title: 'Pets', layout: 'doc' })` returns `---\ntitle: Pets\nlayout: doc\n---`.

## Example

Register the Markdown parser explicitly when overriding the default parser set.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { parserMd } from '@kubb/parser-md'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [parserTs(), parserTsx(), parserMd()],
  plugins: [],
})
```

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-md/CHANGELOG.md)
