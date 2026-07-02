---
layout: doc
title: Kubb TypeScript Parser
description: Prints the Kubb AST to TypeScript source with the official TypeScript compiler, so
  every plugin writes real `.ts`, `.tsx`, `.js`, and `.jsx` files.
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

> [!TIP]
> `@kubb/parser-ts` ships with Kubb and runs by default. Install it on its own only when you set a custom `parsers` list or add other parsers next to it.

`@kubb/parser-ts` takes the `FileNode` your plugins stage and prints it as TypeScript source with the official [TypeScript compiler](https://www.typescriptlang.org/). It resolves import paths, writes the import and export statements, prints JSDoc, and rewrites import extensions based on `output.extension`.

The package exports two parsers, and Kubb selects one by the file extension a plugin writes:

- `parserTs` handles `.ts` and `.js` files.
- `parserTsx` handles `.tsx` and `.jsx` files. Use it for React projects so JSX in generated components is preserved.

Neither parser takes configuration options. You pick the behavior by choosing which parser goes in the `parsers` array. A custom `parsers` array replaces the default set (`parserTs`, `parserTsx`, `parserMd`), and files whose extension has no registered parser are written by joining their sources verbatim, so list every parser your plugins need.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/parser-ts@beta
```

```shell [pnpm]
pnpm add -D @kubb/parser-ts@beta
```

```shell [npm]
npm install --save-dev @kubb/parser-ts@beta
```

```shell [yarn]
yarn add -D @kubb/parser-ts@beta
```

:::

## Example

::: code-group

```typescript [TypeScript (default)]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs],
  plugins: [],
})
```

```typescript twoslash [TypeScript and TSX (React)]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs, parserTsx],
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md)
