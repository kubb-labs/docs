---
layout: doc
title: Architecture
description: How Kubb generates code. The adapter, AST, plugins, parsers, and storage form one layered pipeline from spec to output files.
outline: [2, 3]
---

# Architecture

Kubb turns API specifications into code through a layered pipeline:

- The [adapter](/docs/5.x/guide/concepts/adapters) parses the spec into a universal [AST](/docs/5.x/guide/concepts/ast).
- [Macros](/docs/5.x/guide/going-further/macros) rewrite AST nodes before a plugin reads them.
- [Plugins](/plugins) walk the AST and emit `FileNode`s.
- [Parsers](/docs/5.x/guide/concepts/parsers) convert each `FileNode` into source code.
- [Storage](/docs/5.x/guide/concepts/storage) writes the result to disk.

Each section below summarizes one layer and links to its full page. Start here for the shape of the pipeline, then follow a link when you need the detail.

## Pipeline overview

Every run moves through four stages. Select one to see what it does, or watch it play through from spec to files.

<ArchitecturePipeline />

## Config

`defineConfig` from `kubb/config` pre-wires [`adapterOas`](/docs/5.x/guide/concepts/adapters), the default parsers [`parserTs`, `parserTsx`, `parserMd`](/docs/5.x/guide/concepts/parsers), and [`pluginBarrel`](/plugins/plugin-barrel/). A minimal config only needs `input` and `output`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [],
})
```

> [!NOTE]
> Reach for [`createKubb`](/docs/5.x/reference/kit/engine#createkubb) only when you need a programmatic build or custom tooling.

## [Adapter](/docs/5.x/guide/concepts/adapters)

<FlowDiagram preset="adapter" />

The adapter reads your spec and returns an `InputNode`, so nothing downstream touches the original format. It answers every spec-specific question: nullability, `$ref` resolution, discriminators, and binary detection. [`@kubb/adapter-oas`](/adapters/adapter-oas/) covers OpenAPI 2.0, 3.0, and 3.1, and `defineConfig` selects it for you.

## [AST](/docs/5.x/guide/concepts/ast)

<AstTree />

The AST is the contract between the adapter and the plugins. Every adapter produces one and every plugin reads it, so the same plugin works against any spec. Two visitors walk it: `transform` to rewrite nodes and `collect` to gather them.

## [Macros](/docs/5.x/guide/going-further/macros)

<FlowDiagram preset="macros" />

Macros are a second AST pass. They rewrite schema and operation nodes, one plugin at a time, before generators print code, so you can rename symbols or retype fields without patching the output. Pass them through a plugin's `macros` option.

## [Plugins](/docs/5.x/guide/concepts/plugins)

<PluginAnatomy />

A plugin walks the AST and emits `FileNode`s. Plugins run in array order, so a types plugin can run first and a client plugin after it imports those types. Browse the [plugins catalogue](/plugins) for what ships today.

## [Generators](/docs/5.x/guide/concepts/generators)

<FlowDiagram preset="generator" />

A generator is where a plugin produces code. Each one reads a schema, a single operation, or the whole operation set, and returns the files those nodes become. Splitting a plugin into named generators keeps each one small and lets the engine call the right one for every node.

## [Renderer](/docs/5.x/guide/concepts/renderers)

<FlowDiagram preset="renderer" />

A generator can build `FileNode`s by hand or describe them as components, and [`kubb/jsx`](/docs/5.x/reference/jsx) is the optional JSX path for the second style.

> [!NOTE]
> `kubb/jsx` is optional. Plugins that build `FileNode`s directly with the `factory` node builders from [`kubb/kit`](/docs/5.x/reference/kit) do not need it.

## [Resolvers](/docs/5.x/guide/concepts/resolvers)

<FlowDiagram preset="resolver" />

A resolver answers two questions for every file: its name and its path. Generators ask the resolver instead of building strings, so names stay consistent and one plugin imports another's output by reading its resolver.

## [Parsers](/docs/5.x/guide/concepts/parsers)

<FlowDiagram preset="parsers" />

A parser converts a `FileNode` into a source string. Each one claims a set of file extensions, and Kubb hands every emitted file to the parser that owns its extension. [`@kubb/parser-ts`](/parsers/parser-ts/) and [`@kubb/parser-md`](/parsers/parser-md/) ship by default.

## [Storage](/docs/5.x/guide/concepts/storage)

<FlowDiagram preset="storage" />

The storage driver decides where files land.

- `fsStorage()` writes to disk and skips unchanged files. Default.
- `memoryStorage()` keeps everything in a `Map`, ideal for tests.
- A custom `Storage` targets any other backend.

## Integrations and AI

- [`unplugin-kubb`](/docs/5.x/guide/integrations/) runs Kubb inside your build tool: Vite, Rollup, webpack, esbuild, Rspack, Nuxt, and Astro.
- The [`kubb mcp`](/docs/5.x/reference/commands/mcp) command exposes generation to LLM clients over [MCP](https://modelcontextprotocol.io).
