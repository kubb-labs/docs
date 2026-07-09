---
layout: doc
title: Plugins
description: definePlugin wraps a factory into a typed Plugin, with all lifecycle handlers under one hooks object and the KubbPluginSetupContext that registers generators, resolvers, macros, and options.
outline: [2, 3]
---

# Plugins

Plugins are the main extension point in Kubb. A plugin owns its file naming, its output folder, its lifecycle hooks, and the [generators](./generators) that walk the [AST](/docs/5.x/guide/concepts/ast) and emit `FileNode` objects.

## `definePlugin`

`definePlugin` wraps a factory function and returns a typed `Plugin`. All lifecycle handlers live under one `hooks` object, inspired by [Astro integrations](https://docs.astro.build/en/reference/integrations-reference/).

```typescript twoslash [plugin-example.ts]
import { definePlugin } from 'kubb/kit'

export const pluginExample = definePlugin((options: { prefix?: string } = {}) => ({
  name: 'plugin-example',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      // Register resolvers, generators, and options here.
    },
  },
}))
```

### Plugin shape

| Property       | Type                                 | Required | Description                                                |
| -------------- | ------------------------------------ | -------- | ---------------------------------------------------------- |
| `name`         | `string`                             | Yes      | Unique plugin identifier (e.g., `plugin-ts`)               |
| `dependencies` | `Array<string>`                      | No       | Names of other plugins this one requires                   |
| `options`      | `unknown`                            | No       | User-supplied options passed through to generators         |
| `hooks`        | `{ 'kubb:plugin:setup'?: ...; ... }` | Yes      | Lifecycle handlers (see [Plugin API](/docs/5.x/guide/concepts/plugins)) |

### `KubbPluginSetupContext` methods (passed to `kubb:plugin:setup`)

| Method           | Signature                                                       | Purpose                                                       |
| ---------------- | ----------------------------------------------------------------| ------------------------------------------------------------- |
| `addGenerator`   | `(...generators: Array<Generator>) => void`                     | Register one or more generators for this plugin               |
| `setResolver`    | `(resolver: Partial<Resolver>) => void`                         | Set or partially override the file naming resolver            |
| `addMacro`       | `(macro: Macro) => void`                                        | Add a macro that rewrites AST nodes before generators         |
| `setMacros`      | `(macros: Array<Macro>) => void`                                | Replace this plugin's macros with a new list                  |
| `setOptions`     | `(options: ResolvedOptions) => void`                            | Set the resolved options used by generators                   |
| `injectFile`     | `(file: UserFileNode) => void`                                  | Inject a raw file into the build output, bypassing generation |
| `config`         | `Config`                                                        | The resolved build configuration at setup time                |
| `options`        | `TOptions`                                                      | The plugin's own options as passed by the user                |

> [!IMPORTANT]
> Plugin names should follow the convention `plugin-<feature>` (e.g., `plugin-react-query`, `plugin-zod`). See [Creating plugins](/docs/5.x/guide/going-further/creating-plugins) for naming conventions.

### Related

- [Plugin concepts](/docs/5.x/guide/concepts/plugins)
- [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins)
