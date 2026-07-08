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
> `parserTs` runs by default, so TypeScript output needs no setup. Add it back to a custom `parsers` list when you override the defaults, since a custom list replaces the whole default set.

`@kubb/parser-ts` takes the `FileNode` your plugins stage and prints it as TypeScript source with the official [TypeScript compiler](https://www.typescriptlang.org/). It resolves import paths, writes the import and export statements, prints JSDoc, and rewrites the extensions in those statements based on its [`extension`](#options) option.

The package exports two parser factories, and Kubb selects one by the file extension a plugin writes:

- `parserTs` handles `.ts` and `.js` files.
- `parserTsx` handles `.tsx` and `.jsx` files. Use it for React projects so JSX in generated components is preserved.

Both factories take the same `extension` option and nothing else. You pick the rest of the behavior by choosing which parser goes in the `parsers` array. A custom `parsers` array replaces the default set (`parserTs()`, `parserTsx()`, `parserMd()`), and files whose extension has no registered parser are written by joining their sources verbatim, so list every parser your plugins need.

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
  parsers: [parserTs()],
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
  parsers: [parserTs(), parserTsx()],
  plugins: [],
})
```

:::

## Options

### `extension`

Rewrite the extensions emitted in `import` and `export` statements. Keys are the source extension, values are the output, and an empty string drops the extension. This changes only the module-specifier strings, never the name of the file written to disk.

|           |                                                          |
| --------: | :------------------------------------------------------- |
|     Type: | `Record<FileNode['extname'], FileNode['extname'] \| ''>` |
| Required: | `false`                                                  |
|  Default: | `{ '.ts': '.ts' }`                                       |

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs({ extension: { '.ts': '.js' } }), parserTsx()],
})
```

> [!TIP]
> Use `{ '.ts': '.js' }` for ESM, when the consumer transpiles to JavaScript. Use `{ '.ts': '' }` to drop the extension.

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/parser-ts/CHANGELOG.md)
