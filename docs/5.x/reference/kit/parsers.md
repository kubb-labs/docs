---
layout: doc
title: Parsers
description: defineParser creates a parser that converts a generated file AST into the source string written to disk. Covers the Parser interface, the built-in TypeScript parser, and adding your own.
outline: [2, 3]
---

# Parsers

A parser turns a `FileNode` into the source string written to disk. This page documents `defineParser`, the `Parser` interface, the built-in parsers, and how to add your own. For why parsers exist and where they sit in the pipeline, see [Parsers concepts](/docs/5.x/guide/concepts/parsers).

> [!TIP]
> For TypeScript and JavaScript output use the built-in [`@kubb/parser-ts`](/parsers/parser-ts/). It is added by default when you import `defineConfig` from the `kubb` package. Build a custom parser only when you target a different language, such as Python, Kotlin, or Rust.

## `defineParser`

`defineParser` creates a parser that converts generated file ASTs to formatted source strings. Each parser declares which file extensions it handles via `extNames`. A minimal parser registers its extensions and concatenates each source:

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

> [!IMPORTANT]
> If two parsers register the same extension, the last one in the `parsers` array wins. Order matters.

When no parser matches a file's extension, the file processor joins the file's source strings directly.

## Parser naming convention

Parsers share the layout of [plugins](/docs/5.x/guide/concepts/plugins) and [adapters](/docs/5.x/guide/concepts/adapters):

| Surface             | Pattern                                          | Example                          |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| npm package         | `@<scope>/parser-<name>` or `kubb-parser-<name>` | `@kubb/parser-ts`                |
| Parser runtime name | The output language or format (lowercase)        | `'typescript'`, `'markdown'`     |
| Factory export      | `parser<Name>` (camelCase)                       | `parserTs`, `parserMd`           |

A parser is a factory function that returns a [`Parser`](https://github.com/kubb-labs/kubb/blob/main/packages/core/src/defineParser.ts#L7) object. Call it when you pass it to `parsers:` in `defineConfig`:

```typescript twoslash [naming.ts]
import { defineParser } from 'kubb/kit'

export const parserCustom = defineParser(() => ({
  name: 'custom',
  extNames: ['.custom'],
  parse(file) {
    return file.sources.map((source) => source.name ?? '').join('\n')
  },
  print(...nodes) {
    return nodes.map(String).join('\n')
  },
}))
```

> [!TIP]
> Parsers compose by extension. `parserTs` (`.ts`, `.js`) and `parserTsx` (`.tsx`, `.jsx`) ship in the same [`@kubb/parser-ts`](/parsers/parser-ts/) package and register side by side.

## Creating a custom parser

`defineParser` wraps a factory function and infers the parser type, mirroring `definePlugin`: the factory receives the caller's options, and calling the result without options passes an empty object.

```typescript twoslash [parserPython.ts]
import { defineParser } from 'kubb/kit'

export const parserPython = defineParser(() => ({
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
}))
```

Register it alongside the built-ins:

```typescript [kubb.config.ts]

import { defineConfig } from 'kubb/config'
import { parserTs } from '@kubb/parser-ts'
import { parserPython } from './parserPython.ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  parsers: [parserTs(), parserPython()],
})
```

> [!TIP]
> Set `extNames: undefined` to register a catch-all fallback that runs when no other parser matches. Useful for a default `.txt` writer or for inspecting what files the build produces.
