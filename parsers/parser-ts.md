---
layout: doc
title: Kubb TypeScript Parser
description: Default file parser for Kubb. Converts the universal AST to
  `.ts`/`.tsx` source using the official TypeScript compiler.
outline: 2
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

The package exports two parsers:

- `parserTs` handles `.ts` and `.js` files.
- `parserTsx` handles `.tsx` and `.jsx` files. Use it for React projects so JSX in generated components is preserved.

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

## Import extensions

The parser is a ready-made object. You add it to the `parsers` list, and it takes no options of its own. To change the extension written into generated imports, set `output.extension` on `defineConfig`. The parser reads that map and rewrites each import path.

For example, `output.extension: { '.ts': '.js' }` turns `import { Pet } from './Pet'` into `import { Pet } from './Pet.js'`. Node's ESM resolver expects that `.js` suffix.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', extension: { '.ts': '.js' } },
  adapter: adapterOas(),
  parsers: [parserTs],
  plugins: [],
})
```

```typescript [Generated import]
import type { Pet } from './Pet.js'
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

```typescript twoslash [TSX (React)]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  parsers: [parserTsx],
  plugins: [],
})
```

:::

## See Also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md)
