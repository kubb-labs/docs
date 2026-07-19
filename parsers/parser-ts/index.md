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

# @kubb/parser-ts

> [!TIP]
> `parserTs` runs by default, so TypeScript output needs no setup. Add it back to a custom `parsers` list when you override the defaults, since a custom list replaces the whole default set.

`@kubb/parser-ts` takes the `FileNode` your plugins stage and prints it as TypeScript source with the official [TypeScript compiler](https://www.typescriptlang.org/). It resolves import paths, writes the import and export statements, prints JSDoc, and rewrites import extensions based on the parser's `extension` option.

The package exports two parser factories, and Kubb selects one by the file extension a plugin writes:

- `parserTs()` handles `.ts` and `.js` files.
- `parserTsx()` handles `.tsx` and `.jsx` files. Use it for React projects so JSX in generated components is preserved.

Both accept an `extension` option that rewrites the extensions emitted in `import`/`export` statements, for example `parserTs({ extension: { '.ts': '.js' } })` to emit `.js` imports from `.ts` sources for an ESM dual package. A custom `parsers` array replaces the default set (`parserTs`, `parserTsx`, `parserMd`), and files whose extension has no registered parser are written by joining their sources verbatim, so list every parser your plugins need.

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

## Dependencies

`@kubb/parser-ts` has no plugin dependencies. It is a standalone parser you register on `defineConfig`'s `parsers` array, and needs no other Kubb plugin.

## Example

::: code-group

```typescript twoslash [TypeScript (default)]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs()],
  plugins: [],
})
```

```typescript twoslash [TypeScript and TSX (React)]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTs(), parserTsx()],
  plugins: [],
})
```

:::

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md)
