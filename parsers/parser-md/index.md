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

# @kubb/parser-md

`@kubb/parser-md` lets Kubb emit `.md` and `.markdown` files. Any plugin that writes a markdown source has its output serialized for you.

The parser joins a file's source blocks with blank lines to form the body, and prepends a YAML frontmatter block when `file.meta.frontmatter` is set, so you never add a `yaml` dependency yourself.

> [!TIP]
> `parserMd` runs by default next to `parserTs` and `parserTsx`. Add it back to a custom `parsers` list when you override the defaults, since a custom `parsers` array replaces the whole default set. Files whose extension has no registered parser are written by joining their sources verbatim.

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

## Dependencies

`@kubb/parser-md` has no plugin dependencies. It is a standalone parser you register on `defineConfig`'s `parsers` array, and needs no other Kubb plugin.

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

You can also call `parserMd().print` directly to build a frontmatter envelope. It accepts objects and markdown strings and joins them with blank lines, so `parserMd().print({ title: 'Pets', layout: 'doc' })` returns `---\ntitle: Pets\nlayout: doc\n---`.

## Example

::: code-group

```typescript twoslash [Standalone markdown]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserMd } from '@kubb/parser-md'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserMd()],
  plugins: [],
})
```

```typescript twoslash [Markdown alongside TypeScript]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserMd } from '@kubb/parser-md'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs(), parserTsx(), parserMd()],
  plugins: [],
})
```

:::

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-md/CHANGELOG.md)
