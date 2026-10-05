---
layout: doc
title: Extension model
description: Understand plugin lifecycles, generators, resolvers, macros, and
  renderers when extending Kubb.
outline:
  - 2
  - 3
order: 2
navigation:
  title: Extension model
---

# Extension model

Use an existing [plugin](/plugins) when it generates the output you need. To add an output or replace a pipeline layer, build on `kubb/kit`, a subpath of the `kubb` package.

## Plugins {#plugins}

A plugin factory returns a name, options, and lifecycle hooks. It registers generators and a resolver during `kubb:plugin:setup`, then produces files during generation.

::plugin-anatomy

### Lifecycle {#lifecycle}

Setup runs once per plugin. Kubb then walks schemas and operations, invokes generators, collects files, and runs output passes. Hooks let a plugin observe or change specific stages.

::lifecycle-timeline

The [lifecycle reference](/docs/5.x/reference/kit/hooks) lists the firing order and payloads.

### Dependencies and ordering {#dependencies}

Declared dependencies run before their dependents. Kubb uses `enforce: 'pre'`, normal plugins, then `enforce: 'post'` and declaration order to break ties. Dependencies take priority over `enforce`.

Ordering ignores dependencies absent from the config. A generator's `ctx.requirePlugin(name)` reports a missing required plugin. Resolvers let cooperating plugins read each other's names and paths instead of guessing them.

Post-enforced plugins can process other plugins' emitted files. The built-in barrel plugin uses this to generate re-exports.

## Generators {#generators}

A generator handles `schema` nodes, `operation` nodes, or the complete `operations` batch. Splitting output into generators keeps each task separate. An optional `match` predicate filters schema and operation handlers. It does not filter the batch handler.

Generators return files directly or elements for a renderer. See [Generator reference](/docs/5.x/reference/kit/generators) for handler signatures and context properties.

## Resolvers {#resolvers}

A resolver determines identifiers, filenames, and paths. Generators use the active resolver, and dependent plugins read it to import the correct output.

The plugin's `resolver` option patches its defaults. Use it to rename or relocate output. Use macros to change the underlying schema. See [Override a resolver](/docs/5.x/how-to/resolvers).

## Macros and printers {#macros}

Macros rewrite the AST before generation. Printers turn schema nodes into output for one target, such as TypeScript types or Zod expressions.

Use a macro when the schema meaning changes. Override a printer when one target needs different code. See [Write a macro](/docs/5.x/how-to/macros) and [Override a printer](/docs/5.x/how-to/printers).

## Renderers {#renderers}

Generators can build `FileNode`s with `ast.factory` or return elements that a renderer converts into files. `kubb/jsx` provides the JSX renderer without React. Enable it per generator through `renderer`.

A custom renderer is useful for another templating format. Direct node builders need no renderer. See [Renderer reference](/docs/5.x/reference/kit/renderers) and [JSX reference](/docs/5.x/reference/jsx).

## Kit and engine {#kit}

`kubb/kit` supplies plugin factories, generators, resolvers, adapters, parsers, renderers, storage helpers, AST tools, and diagnostics. `kubb/kit/testing` supplies test helpers.

The engine runs those extensions. Import `defineConfig` from `kubb/config` for CLI configuration or `createKubb` from `kubb` for programmatic builds. Both apply the package defaults. The lower-level `@kubb/core` engine has no package defaults.

## See also

- [Create your first plugin](/docs/5.x/tutorials/creating-plugins)
- [Architecture](/docs/5.x/explanation/architecture)
- [Kit API](/docs/5.x/reference/kit)
