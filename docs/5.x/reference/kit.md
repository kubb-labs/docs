---
layout: doc
title: Kit API
description: The kubb/kit reference for authoring plugins, generators,
  resolvers, renderers, adapters, parsers, and storage backends, plus the ast
  namespace, Diagnostics, the engine surface, and the testing helpers.
outline:
  - 2
  - 3
order: 3
navigation:
  title: Kit
---

# Kit API

Import authoring APIs from `kubb/kit`, included with the `kubb` package.

## Big concepts

| Concept                     | Entry point                                  | What it does                                                             |
| --------------------------- | -------------------------------------------- | ------------------------------------------------------------------------ |
| [Plugins](./kit/plugins)        | `definePlugin`                               | The main extension point. Owns file naming, the output folder, and the lifecycle hooks. |
| [Generators](./kit/generators)  | `defineGenerator`                            | Walks the AST and emits files. A plugin registers one or more.           |
| [Resolvers](./kit/resolvers)    | `createResolver`                             | Decides file names and output paths. Other plugins read them by name.    |
| [Renderers](./kit/renderers)    | `createRenderer`, `jsxRenderer`              | Turns the elements a generator returns into `FileNode`s.                 |
| [Adapters](./kit/adapters)      | `createAdapter`                              | Converts an input spec into the universal AST every plugin reads.        |
| [Parsers](./kit/parsers)        | `defineParser`                               | Turns a `FileNode` into the source string written to disk.               |
| [Storage](./kit/storage)        | `createStorage`, `fsStorage`, `memoryStorage`| Decides where generated files land.                                      |

## Other parts

| Part                                       | Entry point                | What it does                                                     |
| ------------------------------------------ | -------------------------- | --------------------------------------------------------------- |
| [AST and node builders](./kit/ast)             | `ast`                      | The namespace behind `factory` builders, visitors, guards, macros, and printers. |
| [Diagnostics](./kit/diagnostics)           | `Diagnostics`              | Builds and narrows the structured errors Kubb collects during a build. |
| [Engine and configuration](./kit/engine)       | `defineConfig`, `createKubb` | The `kubb`-package surface that runs your plugins.            |
| [Lifecycle hooks](./kit/hooks)                 | `KubbHooks`                | Every `kubb:*` hook a build fires, its payload, and when it fires. |
| [Testing](./kit/testing)                       | `kubb/kit/testing`         | Vitest-backed helpers for testing plugins, generators, and adapters. |

## See also

- [Extension model](/docs/5.x/explanation/extensions)
- [Create your first plugin](/docs/5.x/tutorials/creating-plugins)
- [JSX reference](/docs/5.x/reference/jsx)
