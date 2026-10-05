---
layout: doc
title: Parsers
description: defineParser creates a parser that converts a generated file AST
  into the source string written to disk. Covers the Parser interface, the
  built-in TypeScript parser, and adding your own.
outline:
  - 2
  - 3
order: 6
navigation:
  title: Parsers
  icon: i-iconoir-code
---

# Parsers

A parser turns a `FileNode` into source code.

> [!TIP]
> For TypeScript and JavaScript output use the built-in [`@kubb/parser-ts`](/parsers/parser-ts/). It is added by default when you import `defineConfig` from the `kubb` package. Build a custom parser only when you target a different language, such as Python, Kotlin, or Rust.

## `defineParser`

`defineParser` wraps a factory and infers its parser type. The factory receives caller options, or an empty object when omitted. Declare extensions with `extNames`:

```typescript twoslash [parserText.ts]
import { defineParser } from 'kubb/kit'

export const parserText = defineParser(() => ({
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
}))
```

Wire it into your config:

```typescript [kubb.config.ts]

import { defineConfig } from 'kubb/config'
import { parserTs, parserTsx } from '@kubb/parser-ts'
import { parserText } from './parserText.ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [parserTs(), parserTsx(), parserText()],
})
```

## Parser anatomy

Every value returned from `defineParser` matches the `Parser` interface from [`kubb/kit`](/docs/5.x/reference/kit):

| Property   | Type                                                                      | Required | When called                                  | Purpose                                                                                                                                              |
| ---------- | ------------------------------------------------------------------------- | -------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`     | `string`                                                                  | Yes      |                                              | Unique parser identifier. Convention is `parser-<id>`.                                                                                               |
| `extNames` | `Array<FileNode['extname']> \| undefined`                                 | Yes      |                                              | File extensions this parser handles. Set to `undefined` to register a catch-all fallback.                                                            |
| `parse`    | `(file: FileNode) => string`                                             | Yes      | By the file processor after all plugins run  | Serializes the file's staged sources into the final output string. Must return synchronously.                                                         |
| `print`    | `(...nodes: TNode[]) => string`                                           | Yes      | By plugins, before files are staged          | Renders compiler AST nodes to source text. The node type is parser-specific, for example `ts.Node` for `parserTs`. |
| `copy`     | `(file: FileNode, source: string) => UserFileNode`                        | No       | By the file processor, for each `copy` file  | Describes a copied template's raw content as nodes, for example its imports as `ImportNode`s, in the same shape `injectFile` takes. Kubb builds it with `createFile` and prints it with `parse`. Omit it to write copied files verbatim. |

> [!IMPORTANT]
> If two parsers register the same extension, the last one in the `parsers` array wins. Order matters.

When no parser matches a file's extension, the file processor joins the file's source strings directly.

## Parser naming convention

Parsers share the layout of [plugins](/docs/5.x/explanation/extensions#plugins) and [adapters](/docs/5.x/explanation/architecture#adapters):

| Surface             | Pattern                                          | Example                          |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| npm package         | `@<scope>/parser-<name>` or `kubb-parser-<name>` | `@kubb/parser-ts`                |
| Parser runtime name | The output language or format (lowercase)        | `'typescript'`, `'markdown'`     |
| Factory export      | `parser<Name>` (camelCase)                       | `parserTs`, `parserMd`           |

Call the parser factory when registering it in `parsers`.

> [!TIP]
> Parsers compose by extension. `parserTs` (`.ts`, `.js`) and `parserTsx` (`.tsx`, `.jsx`) ship in the same [`@kubb/parser-ts`](/parsers/parser-ts/) package and register side by side.

Set `extNames: undefined` for a catch-all fallback when no parser matches.
