---
layout: doc
title: Kit API
description: The kubb/kit reference for authoring plugins, generators, resolvers, renderers, adapters, parsers, and storage backends, plus the ast namespace, Diagnostics, the engine surface, and the testing helpers.
outline: [2, 3]
---

# Kit API

`kubb/kit` contains everything you need to build your own plugin and custom logic. Plugins, generators, resolvers, renderers, adapters, parsers, and storage backends all start here. It is a subpath of the top-level `kubb` package, so there is nothing extra to install. Import straight from `kubb/kit`.

## Big concepts

The seven pieces you reach for when you build something new. Each has its own page.

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

- [Kit concepts](/docs/5.x/guide/concepts/kit) for why the authoring toolkit is a separate surface from the engine
- [JSX API reference](/docs/5.x/reference/jsx) for `kubb/jsx`, the JSX renderer
- [Plugin concepts](/docs/5.x/guide/concepts/plugins) for lifecycle hooks, generators, resolvers, and the plugin registry
- [AST concepts](/docs/5.x/guide/concepts/ast) for `InputNode`, `OperationNode`, `SchemaNode`, and traversal
- [Adapter concepts](/docs/5.x/guide/concepts/adapters) on how adapters convert specs to the universal AST
- [Parser concepts](/docs/5.x/guide/concepts/parsers) on converting `FileNode` AST to source strings
- [Macros concepts](/docs/5.x/guide/going-further/macros) for `defineMacro`, `composeMacros`, and `applyMacros`
- [Barrel files](/docs/5.x/guide/going-further/barrel-files) for barrel generation with `@kubb/plugin-barrel`
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step guide to building a full plugin
- [Programmatic usage recipes](/docs/5.x/guide/recipes#programmatic-build) with `createKubb` usage patterns
- [Configuration reference](/docs/5.x/reference/configuration) for all `defineConfig` options
