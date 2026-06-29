---
layout: doc
title: Macros - Composable AST transforms
description: A macro is a named, composable transform over Kubb's AST. Macros rewrite schema and operation nodes before generators print code, and the same macro works across every adapter and every output target.
outline: deep
---

# Macros

Macros are the second layer of `@kubb/ast`, on top of the [AST](/docs/5.x/guide/concepts/ast) node tree that adapters produce and generators read. A macro is a named, composable transform that rewrites those nodes before generators print code. Use one to rename a symbol, retype a field, strip metadata, or normalize a shape without forking an adapter or a generator. Because macros run on the shared AST, the same macro works across every input adapter (OpenAPI, AsyncAPI, JSON Schema) and every output target (TypeScript, Zod, and any printer a plugin supplies).

The engine (`defineMacro`, `composeMacros`, `applyMacros`, and the `Macro` type) lives on the `@kubb/ast` root, next to the node tree it transforms. The built-in macro presets live on the `@kubb/ast/macros` subpath, one per file.

## Shape

A macro carries the per-kind callbacks of a [visitor](/docs/5.x/guide/concepts/ast#visitors), plus a `name`, an optional `enforce` order, and an optional `when` gate.

```typescript [Type definition]
type Macro = {
  name: string
  enforce?: 'pre' | 'post'
  when?: (node: Node) => boolean
  schema?(node: SchemaNode, context): SchemaNode | null | undefined
  operation?(node: OperationNode, context): OperationNode | null | undefined
  // input, output, property, parameter, response
}
```

Each callback returns a replacement node, or `undefined` to leave the node untouched. A macro that changes nothing returns the original reference, so an unchanged tree is reused, not rebuilt.

## Writing a macro

`defineMacro` types a macro and keeps its definition in one place, the way `definePlugin` does for plugins.

```typescript twoslash [macro.ts]
import { ast } from '@kubb/core'

const macroIntegerToString = ast.defineMacro({
  name: 'integer-to-string',
  schema(node) {
    return node.type === 'integer' ? { ...node, type: 'string' } : undefined
  },
})
```

The `when` gate skips a macro for nodes it does not care about, and `enforce` places a macro before or after the unmarked ones.

```typescript twoslash [enforce.ts]
import { ast } from '@kubb/core'

const macroUntagged = ast.defineMacro({
  name: 'untagged',
  enforce: 'post',
  when: (node) => node.kind === 'Operation',
  operation(node) {
    return node.tags?.length ? undefined : { ...node, tags: ['untagged'] }
  },
})
```

## Composing macros

A plugin runs a list of macros. They apply in order, so a later macro sees the output of an earlier one. `composeMacros` folds a list into a single visitor, and `applyMacros` runs the list over a tree.

```typescript twoslash [compose.ts]
import { ast } from '@kubb/core'

const macroDto = ast.defineMacro({
  name: 'dto',
  schema(node) {
    return node.type === 'object' ? { ...node, name: node.name ? `${node.name}Dto` : node.name } : undefined
  },
})

const macroFetchPrefix = ast.defineMacro({
  name: 'fetch-prefix',
  operation(node) {
    return { ...node, operationId: node.operationId.replace(/^get/, 'fetch') }
  },
})

const root = ast.factory.createInput({ schemas: [], operations: [] })
const next = ast.applyMacros(root, [macroDto, macroFetchPrefix])
```

## Using macros in a plugin

Pass macros through a plugin's `macros` option, or register them from `kubb:plugin:setup` with `addMacro` and `setMacros`. Macros run per plugin, so one plugin's macros never change the nodes another plugin sees.

```typescript twoslash [plugin.ts]
import { ast, definePlugin } from '@kubb/core'

const macroDropDescriptions = ast.defineMacro({
  name: 'drop-descriptions',
  schema(node) {
    return 'description' in node && node.description ? { ...node, description: undefined } : undefined
  },
})

export const pluginRename = definePlugin(() => ({
  name: 'plugin-rename',
  hooks: {
    'kubb:plugin:setup'(ctx) {
      ctx.addMacro(macroDropDescriptions)
    },
  },
}))
```

Macros run before resolver options are computed, so a renamed `operationId` or `SchemaNode.name` flows into `resolveOptions`, `resolvePath`, and `resolveFile`.

> [!TIP]
> Keep macros pure. Build a new node and return it rather than mutating the input, since the AST is shared by reference.

## Built-in macros

`@kubb/ast/macros` ships built-in macros for common schema normalizations that any adapter can apply. Import them like any macro and compose them with your own.

`macroSimplifyUnion` drops union members that a broader member already covers, such as a single-value string enum next to a plain `string`. `macroDiscriminatorEnum` rewrites a discriminator property into a string enum of its allowed values, and `macroEnumName` names an inline enum from the schema and property it belongs to. The last two read options, so you call them to build a macro.

```typescript twoslash [presets.ts]
import { ast } from '@kubb/core'
import { macroDiscriminatorEnum, macroSimplifyUnion } from '@kubb/ast/macros'

const root = ast.factory.createInput({ schemas: [], operations: [] })
const next = ast.applyMacros(root, [macroSimplifyUnion, macroDiscriminatorEnum({ propertyName: 'kind', values: ['cat', 'dog'] })])
```

## Sharing macros

A macro is a plain value, so you export it and import it wherever you need it. Group related macros in a module and pull them into any plugin or project, the same way you would with plugins.
