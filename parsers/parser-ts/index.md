---
layout: doc
title: Kubb TypeScript Parser
description: Prints the Kubb AST to TypeScript source with the official
  TypeScript compiler, so every plugin writes real `.ts`, `.tsx`, `.js`, and
  `.jsx` files.
outline: deep
kind: parser
id: parser-ts
name: TypeScript
category: typescript
type: official
npmPackage: "@kubb/parser-ts"
repo: https://github.com/kubb-labs/kubb
docsPath: /parsers/parser-ts
featured: true
icon:
  light: https://kubb.dev/feature/typescript.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - typescript
  - tsx
  - parser
  - printer
  - ast
resources:
  documentation: https://kubb.dev/parsers/parser-ts
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md
---

# @kubb/parser-ts

Print Kubb's AST with the official [TypeScript compiler](https://www.typescriptlang.org/).

- Resolve imports and emit exports and JSDoc.
- Rewrite import extensions with [`extension`](/parsers/parser-ts/reference/options#extension).
- `parserTs` and `parserTsx` run by default alongside `parserMd`.

| Parser | File extensions |
| --- | --- |
| `parserTs()` | `.ts`, `.js` |
| `parserTsx()` | `.tsx`, `.jsx` |

> [!IMPORTANT]
> A custom `parsers` array replaces the default set. Include every parser your plugins need. Unmatched files are written as source text.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/parser-ts
```

```shell [pnpm]
pnpm add -D @kubb/parser-ts
```

```shell [npm]
npm install --save-dev @kubb/parser-ts
```

```shell [yarn]
yarn add -D @kubb/parser-ts
```

::

## Dependencies

- No plugin dependencies.
- Register custom parsers on `defineConfig.parsers`.

## Example

Override import extensions while keeping every default parser registered.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { parserMd } from '@kubb/parser-md'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [
    parserTs({ extension: { '.ts': '.js' } }),
    parserTsx(),
    parserMd(),
  ],
  plugins: [pluginTs()],
})
```

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md)
