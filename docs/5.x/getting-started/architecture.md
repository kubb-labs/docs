---
layout: doc
title: Architecture
description: Learn how Kubb generates code. Adapter, AST, plugins, renderer, parsers, and storage form one layered pipeline from spec to output files.
outline: [2, 3]
---

# Architecture

Kubb transforms API specifications into code through a layered pipeline: the [adapter](/docs/5.x/concepts/adapters) parses the spec into a universal [AST](/docs/5.x/concepts/ast), [macros](/docs/5.x/concepts/macros) rewrite AST nodes before a plugin reads them, [plugins](/plugins) walk the AST and emit `FileNode`s, [parsers](/docs/5.x/concepts/parsers) convert each `FileNode` into source code, and [storage](/docs/5.x/concepts/storage) writes the result to disk.

## Pipeline overview

```mermaid
flowchart LR
    Config["Config\nkubb.config.ts"] --> Setup["Setup\nAdapter → AST"]
    Setup --> Build["Build\nMacros · Plugins · Renderer"]
    Build --> FileProcessor["File processor\nParsers → Storage"]
```

## Config

`defineConfig` from the `kubb` package pre-wires [`adapterOas`](/docs/5.x/concepts/adapters), [`parserTs`, `parserTsx`](/docs/5.x/concepts/parsers), and [`pluginBarrel`](/plugins/plugin-barrel), so a minimal config only needs `input` and `output`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [],
})
```

> [!NOTE]
> Import from [`@kubb/core`](/docs/5.x/api/core) only when you need the lower-level API for programmatic builds or custom tooling.

## [Adapter](/docs/5.x/concepts/adapters)

```mermaid
flowchart LR
    Input["Input spec\nOpenAPI 2/3"] --> Parse["adapter.parse(source)"]
    Parse --> InputNode["InputNode\nschemas + operations"]
```

An adapter converts an input specification into the universal [AST](/docs/5.x/concepts/ast). `adapter.parse(source)` returns an `InputNode`; `adapter.getImports(node, resolve)` tracks cross-references so plugins emit correct import paths.

The official adapter for OpenAPI 2.0, 3.0, and 3.1 is [`@kubb/adapter-oas`](/adapters/adapter-oas), selected automatically by `defineConfig`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas({ validate: true, dateType: 'date' }),
})
```

See [Adapters](/docs/5.x/concepts/adapters) for the full list of options and details on building a custom adapter.

## [AST](/docs/5.x/concepts/ast)

The AST is the intermediate representation between the [adapter](/docs/5.x/concepts/adapters) and the [plugins](/plugins). Every adapter produces an `InputNode`; every plugin consumes it. Plugins never read the raw spec, so the same plugin works with any adapter.

```
InputNode
├── schemas: SchemaNode[]            (named, reusable schemas)
│   └── consumed by plugins          → FileNode (e.g. type aliases, enums)
└── operations: OperationNode[]
    ├── parameters: ParameterNode[]  → SchemaNode
    ├── requestBody?: RequestBodyNode → content: ContentNode[] → SchemaNode
    ├── responses: ResponseNode[]    → content: ContentNode[] → SchemaNode
    └── consumed by plugins          → FileNode (e.g. client functions, hooks)
```

[`@kubb/ast`](/docs/5.x/concepts/ast) ships three visitor patterns:

| Visitor                     | Purpose                                                               |
| --------------------------- | --------------------------------------------------------------------- |
| `walk(root, visitors)`      | Async traversal for logging, validation, and side effects.            |
| `transform(root, visitors)` | Produces a modified copy of the tree. Return `null` to remove a node. |
| `collect(root, visitors)`   | Gathers matching nodes into a flat array.                             |

## [Macros](/docs/5.x/concepts/macros)

```mermaid
flowchart LR
    InputNode["InputNode"] --> Macros["applyMacros(node, [...])"]
    Macros --> Transformed["InputNode\ntransformed"]
```

Macros are the second layer of [`@kubb/ast`](/docs/5.x/concepts/ast). A macro is a named, composable transform that rewrites schema and operation nodes before a plugin's generators print code, so you can rename symbols, retype fields, or normalize shapes without forking an adapter or a generator. Because macros run on the shared AST, the same macro works across every adapter and every output target.

Macros run per plugin, so one plugin's macros never change the nodes another plugin sees. Pass them through a plugin's `macros` option, or register them from `kubb:plugin:setup` with `addMacro`. They run before resolver options are computed, so a renamed `operationId` or `SchemaNode.name` flows into `resolveOptions`, `resolvePath`, and `resolveFile`.

```typescript twoslash [kubb.config.ts]
// @noErrors
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { macroSimplifyUnion } from '@kubb/ast/macros'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs({ macros: [macroSimplifyUnion] })],
})
```

See [Macros](/docs/5.x/concepts/macros) for writing macros, composing them, and the built-in presets.

## Plugins

```mermaid
flowchart LR
    InputNode["InputNode"] --> Plugin["Plugin\ngen.schema() / gen.operation()"]
    Plugin -->|"returns JSX"| Renderer["Renderer\n@kubb/renderer-jsx"]
    Plugin -->|"returns FileNode[]"| Files["FileNode[]"]
    Renderer --> Files
```

Plugins walk the [AST](/docs/5.x/concepts/ast) and emit `FileNode`s. They run in array order; earlier plugins produce types that later plugins can import.

```typescript twoslash [kubb.config.ts]
// @noErrors
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginTs(), pluginClient({ importPath: '@/lib/axios' })],
})
```

### Types and clients

| Package                                         | Generates                                                                                                                               |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| [`@kubb/plugin-ts`](/plugins/plugin-ts)         | TypeScript types and interfaces                                                                                                         |
| [`@kubb/plugin-client`](/plugins/plugin-client) | HTTP client functions ([Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API), [Axios](https://axios-http.com), or custom) |

### Data-fetching hooks

| Package                                                   | Generates                                                    |
| --------------------------------------------------------- | ------------------------------------------------------------ |
| [`@kubb/plugin-react-query`](/plugins/plugin-react-query) | [TanStack Query](https://tanstack.com/query) hooks for React |
| [`@kubb/plugin-vue-query`](/plugins/plugin-vue-query)     | [TanStack Query](https://tanstack.com/query) hooks for Vue   |

### Validation and mocking

| Package                                       | Generates                                      |
| --------------------------------------------- | ---------------------------------------------- |
| [`@kubb/plugin-zod`](/plugins/plugin-zod)     | [Zod](https://zod.dev) validation schemas      |
| [`@kubb/plugin-faker`](/plugins/plugin-faker) | [Faker.js](https://fakerjs.dev) data factories |
| [`@kubb/plugin-msw`](/plugins/plugin-msw)     | [MSW](https://mswjs.io) request handlers       |

### Tooling

| Package                                           | Purpose                                                                                         |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| [`@kubb/plugin-cypress`](/plugins/plugin-cypress) | [Cypress](https://www.cypress.io) test scaffolding                                              |
| [`@kubb/plugin-redoc`](/plugins/plugin-redoc)     | Embeds [Redoc](https://redocly.com/docs/redoc/)-rendered API docs                               |
| [`@kubb/plugin-mcp`](/plugins/plugin-mcp)         | Generates [MCP](https://modelcontextprotocol.io)-compatible tools and schemas for AI assistants |

See the [plugins catalogue](/plugins) for the full list.

## Renderer

Plugins can use [`@kubb/renderer-jsx`](/docs/5.x/api/core) to describe generated files as React components instead of constructing `FileNode`s by hand.

> [!NOTE]
> `@kubb/renderer-jsx` is optional. Plugins that build `FileNode`s directly with factory functions from [`@kubb/ast`](/docs/5.x/concepts/ast) do not need it.

## [Parsers](/docs/5.x/concepts/parsers)

```mermaid
flowchart LR
    Files["FileNode[]"] --> Parser["parser.parse(file)\nby file extension"]
    Parser --> Source["source string"]
    Source --> Storage["storage.setItem(path, source)"]
    Storage --> Out[("disk / memory")]
```

A parser converts a `FileNode` into a source string. Each parser declares which file extensions it handles; Kubb dispatches every emitted file to the first matching parser.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { parserTs, parserTsx } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  parsers: [parserTs, parserTsx],
})
```

> [!IMPORTANT]
> When two parsers claim the same extension, the first one wins.

| Package                                 | Extensions                   | Description                                                                                                  |
| --------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------------------------ |
| [`@kubb/parser-ts`](/parsers/parser-ts) | `.ts`, `.js`, `.tsx`, `.jsx` | Uses the TypeScript compiler to print, deduplicate, and resolve imports. Included automatically with `kubb`. |

## [Storage](/docs/5.x/concepts/storage)

The storage driver controls where Kubb writes generated files. Default is `fsStorage()`. Use `memoryStorage()` for testing, or implement `Storage` to target any backend.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { memoryStorage } from '@kubb/core'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  storage: memoryStorage(),
})
```

| Driver            | Description                                                                          |
| ----------------- | ------------------------------------------------------------------------------------ |
| `fsStorage()`     | Writes to disk. Skips unchanged files. Default.                                      |
| `memoryStorage()` | Stores output in a `Map`. Nothing touches disk. Ideal for tests.                     |
| Custom            | Implement `Storage` with `createStorage` to write to S3, a database, or any backend. |

## Foundation packages

| Package                                    | Purpose                                                                                                                                                                          |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`kubb`](/docs/5.x/api/core)               | Umbrella package. Exports `defineConfig` and bundles `adapterOas`, `parserTs`, `parserTsx`, and `pluginBarrel` for a zero-config setup.                                          |
| [`@kubb/core`](/docs/5.x/api/core)         | Lower-level runtime with `createKubb`, `definePlugin`, `defineParser`, `createAdapter`, and storage APIs. Use for programmatic generation or custom tooling.                     |
| [`@kubb/cli`](/docs/5.x/api/commands/)     | Provides the `kubb` command-line binary. Reads `kubb.config.ts` and runs the generation pipeline.                                                                                |
| [`@kubb/ast`](/docs/5.x/concepts/ast)      | Universal AST layer. Includes all node factories, `walk`, `transform`, `collect`, type guards, and ref helpers. The macro engine lives on the root and the presets on `@kubb/ast/macros`. |
| [`@kubb/parser-ts`](/parsers/parser-ts)    | TypeScript and TSX parser. Included automatically with the `kubb` package.                                                                                                       |
| [`@kubb/renderer-jsx`](/docs/5.x/api/core) | JSX-based rendering for plugins that build files from React components.                                                                                                          |

## Build-tool integrations

| Package                                    | Description                                                                                                                                                                                                                                                                                                           |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`unplugin-kubb`](/docs/5.x/integrations/) | Runs Kubb during your build via [unplugin](https://github.com/unjs/unplugin). Works with [Vite](https://vite.dev), [Rollup](https://rollupjs.org), [webpack](https://webpack.js.org), [esbuild](https://esbuild.github.io), [Rspack](https://rspack.dev), [Nuxt](https://nuxt.com), and [Astro](https://astro.build). |

See the [Integrations](/docs/5.x/integrations/) page for setup instructions for each build tool.

## Servers

| Package                                   | Purpose                                                                                                     |
| ----------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [`@kubb/mcp`](/docs/5.x/api/commands/mcp) | Standalone [MCP](https://modelcontextprotocol.io) server that lets LLM clients trigger generation directly. |
