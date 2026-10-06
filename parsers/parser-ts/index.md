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

`@kubb/parser-ts` prints Kubb's AST as TypeScript using the official [TypeScript compiler](https://www.typescriptlang.org/). It resolves imports, emits exports and JSDoc, and applies the [`extension`](./reference/options#extension) mapping.

- `parserTs()` handles `.ts` and `.js`.
- `parserTsx()` handles `.tsx` and `.jsx`.

Both run by default alongside `parserMd`. A custom `parsers` array replaces that default set. Include every parser your plugins need. Unmatched files are written as source text.

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

No plugin dependencies. The parser registers on `defineConfig.parsers`.

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
