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
icon:
  light: https://kubb.dev/feature/markdown.svg
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
dependencies: []
resources:
  documentation: https://kubb.dev/parsers/parser-md
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/parser-md/CHANGELOG.md
---

# @kubb/parser-md

Generate `.md` and `.markdown` files.

- Join source blocks and prepend [`file.meta.frontmatter`](/parsers/parser-md/reference/options#frontmatter) as YAML.
- Runs by default with the TypeScript parsers. Takes no options.

> [!IMPORTANT]
> A custom `parsers` array replaces the default set. Include every parser your plugins need. Unmatched files are written as source text.

## Installation

Ships with `kubb`, no extra install.

## Dependencies

- No plugin dependencies.
- Register custom parsers on `defineConfig.parsers`.

## Example

Register the Markdown parser explicitly when overriding the default parser set.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { parserMd } from '@kubb/parser-md'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [parserTs(), parserTsx(), parserMd()],
  plugins: [],
})
```
