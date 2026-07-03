---
layout: doc
title: Parsers API - defineParser and the Parser interface
description: Build Kubb parsers with defineParser. Register file extensions, render AST nodes with print, and serialize a FileNode into the final source string with parse.
outline: deep
---

# Parsers API

A parser turns a `FileNode` into the source string written to disk. This page documents `defineParser`, the `Parser` interface, the built-in parsers, and how to add your own. For why parsers exist and where they sit in the pipeline, see [Parsers concepts](/docs/5.x/guide/concepts/parsers).

> [!TIP]
> For TypeScript and JavaScript output use the built-in [`@kubb/parser-ts`](/parsers/parser-ts/). It is added by default when you import `defineConfig` from the `kubb` package. Build a custom parser only when you target a different language, such as Python, Kotlin, or Rust.

## Quick start

A minimal parser registers its extensions and concatenates each source:

```typescript twoslash [parserText.ts]
import { defineParser } from '@kubb/core'

export const parserText = defineParser({
  name: 'parser-text',
  extNames: ['.txt'],
  parse(file) {
    return file.sources
      .flatMap((source) => source.nodes ?? [])
      .map((node) => (node.kind === 'Text' ? node.value : ''))
      .join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

Wire it into your config:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { parserText } from './parserText.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx, parserText],
})
```

## Anatomy

Every value returned from `defineParser` matches the `Parser` interface from [`@kubb/core`](https://www.npmjs.com/package/@kubb/core):

| Property   | Type                                                                      | Required | When called                                  | Purpose                                                                                                                                              |
| ---------- | ------------------------------------------------------------------------- | -------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | `string`                                                                  | Yes      |                                              | Unique parser identifier. Convention is `parser-<id>`.                                                                                               |
| `extNames` | `Array<FileNode['extname']> \| undefined`                                 | Yes      |                                              | File extensions this parser handles. Set to `undefined` to register a catch-all fallback.                                                            |
| `parse`    | `(file: FileNode, options?: { extname?: FileNode['extname'] }) => string` | Yes      | By the file processor after all plugins run  | Serializes the file's staged sources into the final output string. Must return synchronously.                                                         |
| `print`    | `(...nodes: TNode[]) => string`                                           | Yes      | By plugins, before files are staged          | Renders compiler AST nodes to source text. The node type is parser-specific, for example `ts.Node` for `parserTs`. |

> [!IMPORTANT]
> If two parsers register the same extension, the first one in the `parsers` array wins. Order matters.

> [!NOTE]
> `parse()` is synchronous. The file processor streams files through a synchronous pipeline, so returning a `Promise` is not supported. Do async work before the file reaches the parser and pass the result through `FileNode`.

> [!NOTE]
> Formatting and linting (Prettier, Biome, oxlint) run after `parse()`. Keep `parse()` focused on producing syntactically valid output.

When no parser matches a file's extension, the file processor joins the file's source strings directly.

## Naming convention

Parsers share the layout of [plugins](/docs/5.x/guide/concepts/plugins) and [adapters](/docs/5.x/guide/concepts/adapters):

| Surface             | Pattern                                          | Example                          |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| npm package         | `@<scope>/parser-<name>` or `kubb-parser-<name>` | `@kubb/parser-ts`                |
| Parser runtime name | The output language or format (lowercase)        | `'typescript'`, `'markdown'`     |
| Factory export      | `parser<Name>` (camelCase)                       | `parserTs`, `parserMd`           |

Parsers export a plain [`Parser`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineParser.ts#L7) object, not a factory function. Pass them directly to `parsers:` in `defineConfig`:

```typescript twoslash [naming.ts]
import { defineParser } from '@kubb/core'

export const parserCustom = defineParser({
  name: 'custom',
  extNames: ['.custom'],
  parse(file) {
    return file.sources.map((source) => source.name ?? '').join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

> [!TIP]
> Parsers compose by extension. `parserTs` (`.ts`, `.js`) and `parserTsx` (`.tsx`, `.jsx`) ship in the same [`@kubb/parser-ts`](/parsers/parser-ts/) package and register side by side.

## Built-in parsers

### `@kubb/parser-ts`

The default parser for TypeScript and JavaScript output. It uses the official TypeScript compiler to resolve import paths, deduplicate declarations, print JSDoc, and rewrite extensions based on `output.extension`. See the [`@kubb/parser-ts` reference](/parsers/parser-ts/) for the full option list.

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

| Export      | Extensions handled | Notes                                   |
| ----------- | ------------------ | --------------------------------------- |
| `parserTs`  | `.ts`, `.js`       | TypeScript and plain JavaScript output. |
| `parserTsx` | `.tsx`, `.jsx`     | Same as `parserTs` with JSX support.    |

Both expose `parse(file, options?)` and `print(...nodes: ts.Node[])`. Call `parserTs.print(node)` from a plugin to render a TypeScript compiler node to its source string before staging it on `FileNode.sources`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx],
})
```

> [!TIP]
> `defineConfig` from the `kubb` package installs `parserTs`, `parserTsx`, and `parserMd` automatically. Set `parsers:` only when you add a custom parser or need to change the registration order.

## Creating a custom parser

Use `defineParser` from [`@kubb/core`](/docs/5.x/reference/core). It is an identity wrapper that infers the parser type. It returns the object you pass in unchanged, with no per-build options:

```typescript twoslash [parserPython.ts]
import { defineParser } from '@kubb/core'

export const parserPython = defineParser({
  name: 'parser-python',
  extNames: ['.py', '.pyi'],
  parse(file) {
    const lines: Array<string> = []

    if (file.banner) {
      lines.push(file.banner)
    }

    for (const source of file.sources) {
      for (const node of source.nodes ?? []) {
        if (node.kind === 'Text') {
          lines.push(node.value)
        }
      }
    }

    if (file.footer) {
      lines.push(file.footer)
    }

    return lines.join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
})
```

Register it alongside the built-ins:

```typescript twoslash [kubb.config.ts]
// @errors: 2307
import { defineConfig } from 'kubb/config'
import { parserTs } from '@kubb/parser-ts'
import { parserPython } from './parserPython.ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserPython],
})
```

> [!TIP]
> Set `extNames: undefined` to register a catch-all fallback that runs when no other parser matches. Useful for a default `.txt` writer or for inspecting what files the build produces.

> [!NOTE]
> `parse()` runs synchronously, so external formatting (a service call, a child process, or a worker thread) must finish before the file reaches the parser. Stage the pre-formatted output on `FileNode.sources[].nodes` inside a generator, then let the parser join it verbatim.

## Streaming

The file processor is internal to `@kubb/core` and processes files one at a time. The build driver enqueues each file as plugins emit it, the processor runs it through `parse()`, and the result lands in storage without buffering the full set. Progress surfaces as `start`, `update` (with `{ file, source, processed, total, percentage }`), and `end` events on the main event bus, which the built-in reporters render. Memory stays flat regardless of build size because each file is pulled through the pipeline one at a time.
