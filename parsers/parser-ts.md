---
layout: doc
title: Kubb TypeScript Parser
description: Default file parser for Kubb. Converts the universal AST to
  `.ts`/`.tsx` source using the official TypeScript compiler.
outline: 2
kind: parser
id: parser-ts
---

> [!TIP]
> `@kubb/parser-ts` is bundled with Kubb and used automatically when no `parsers` option is set. Install it explicitly only when combining it with other parsers or providing a fully custom parser list.

`@kubb/parser-ts` takes the `FileNode` staged by your plugins and prints it as TypeScript source with the official [TypeScript compiler](https://www.typescriptlang.org/). It resolves import paths, deduplicates declarations, prints JSDoc, and rewrites extensions based on `output.extension`.

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

## Options

### extname

Controls which extension is written into the generated import specifiers. Set `.js` for ESM-compatible output, `.tsx` for React projects. Leave unset for the TypeScript default.

To rewrite extensions in the generated source (e.g. `./foo` → `./foo.js`), use `output.extension` in `defineConfig`, not this option.

|           |                                                |
| --------: | :--------------------------------------------- |
|     Type: | `'.ts' \| '.js' \| '.tsx' \| '.jsx' \| string` |
| Required: | `false`                                        |
|  Default: | `'.ts'`                                        |

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

```typescript [TSX (React)]
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
