---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-effect.
outline: deep
---

# Options

`pluginEffect` accepts the following options.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`output`](#output) | `Output` | `{ path: 'effect', barrel: { type: 'named' } }` | Where the generated files are written and exported |
| [`group`](#group) | `Group` | None | Split output into per-tag or per-path folders |
| [`importPath`](#importpath) | `string` | `'effect/Schema'` | Module used for the generated Schema namespace import |
| [`regexType`](#regextype) | `'literal' \| 'constructor'` | `'constructor'` | How an OpenAPI `pattern` is written |
| [`include`](#include) | `Array<Include>` | None | Keep only operations that match |
| [`exclude`](#exclude) | `Array<Exclude>` | None | Skip operations that match |
| [`override`](#override) | `Array<Override>` | None | Apply different options per pattern |
| [`resolver`](#resolver) | `ResolverPatch<ResolverEffect>` | None | Customize generated names and file paths |
| [`printer`](#printer) | `{ nodes?: PrinterEffectNodes }` | None | Replace the handler for a schema type |
| [`macros`](#macros) | `Array<Macro>` | None | Rewrite AST nodes before printing |

### output

Controls where the generated `.ts` files are written and how Kubb exports them.

#### output.path

The plugin resolves this folder against the global `output.path` from `defineConfig`. For one generated file, set `output.mode: 'file'` and include a `.ts` extension.

|          |            |
| -------: | :--------- |
|    Type: | `string`   |
| Required: | `false`   |
| Default: | `'effect'` |

#### output.mode

`'directory'` writes one file per operation or component. `'file'` combines the generated schemas in the file named by `output.path`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `'directory' \| 'file'` |
| Required: | `false`                 |
|  Default: | `'directory'`           |

#### output.barrel

<!--@include: ../../../snippets/how-to/barrel.md-->

#### output.banner

<!--@include: ../../../snippets/how-to/output-banner.md-->

#### output.footer

<!--@include: ../../../snippets/how-to/output-footer.md-->

### group

<!--@include: ../../../snippets/how-to/grouping.md-->

#### group.type

<!--@include: ../../../snippets/how-to/group-type.md-->

#### group.name

The function turns a tag or path key into the subdirectory under `output.path`.

|           |                                          |
| --------: | :--------------------------------------- |
|     Type: | `(context: { group: string }) => string` |
| Required: | `false`                                  |
|  Default: | `({ group }) => camelCase(group)`        |

### importPath

Sets the module specifier for `import * as Schema from '...'` in generated files. A custom module must export the Effect Schema API as a namespace-compatible module.

|           |                     |
| --------: | :------------------ |
|     Type: | `string`            |
| Required: | `false`             |
|  Default: | `'effect/Schema'`   |

### regexType

Controls the source emitted for OpenAPI `pattern` checks.

- `'constructor'` emits `new RegExp('^[a-z]+$')` and is the default.
- `'literal'` emits `/^[a-z]+$/`.

|           |                              |
| --------: | :--------------------------- |
|     Type: | `'literal' \| 'constructor'` |
| Required: | `false`                      |
|  Default: | `'constructor'`              |

### include

<!--@include: ../../../snippets/how-to/include.md-->

### exclude

<!--@include: ../../../snippets/how-to/exclude.md-->

### override

<!--@include: ../../../snippets/how-to/override.md-->

### resolver

Changes generated symbols and file paths. Methods omitted from the patch keep the behavior from `resolverEffect`.

The default resolver intentionally uses names such as `Pet` for both the schema and the type. Add a suffix if the same barrel also exports `plugin-ts` output.

```typescript [kubb.config.ts]
import { pluginEffect } from '@kubb/plugin-effect'

pluginEffect({
  resolver: {
    name(name) {
      return `${this.default.name(name)}Effect`
    },
  },
})
```

See [Override a resolver](/docs/5.x/guide/going-further/resolvers) for the resolver context.

### printer

Replaces the handler for a schema node type. Every handler returns the runtime expression, decoded type, and encoded type so the three representations cannot drift apart.

`this.base(node)` returns the built-in result. `this.transform(node)` prints a nested node.

```typescript [kubb.config.ts]
import { pluginEffect } from '@kubb/plugin-effect'

pluginEffect({
  printer: {
    nodes: {
      string(node) {
        const base = this.base(node)
        if (!base) return null

        return {
          ...base,
          runtime: `${base.runtime}.annotate({ title: 'Custom string' })`,
        }
      },
    },
  },
})
```

See the [printer guide](/docs/5.x/guide/going-further/printers) for the complete handler contract.

### macros

<!--@include: ../../../snippets/how-to/macros-option.md-->
