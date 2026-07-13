---
layout: doc
title: Generators
description: defineGenerator declares a named generator unit that walks the AST and emits files. Covers the schema, operation, and operations methods and the GeneratorContext passed to each.
outline: [2, 3]
---

# Generators

## `defineGenerator` {#defineGenerator}

`defineGenerator` declares a named generator unit consumed by a plugin. Generators walk the [AST](/docs/5.x/guide/concepts/ast) and emit files. The engine calls each method for the matching node type during the generation loop.

Each generator method returns `TElement | Array<FileNode> | void`. Returning a renderer element (for example JSX from [`kubb/jsx`](/docs/5.x/reference/jsx)) requires a `renderer` factory on the generator.

```typescript twoslash [my-generator.ts]
import { ast, defineGenerator } from 'kubb/kit'

const myGenerator = defineGenerator({
  name: 'my-generator',
  operation(node, ctx) {
    return [
      ast.factory.createFile({
        baseName: `${node.operationId}.ts`,
        path: `./${node.operationId}.ts`,
        sources: [
          ast.factory.createSource({
            nodes: [ast.factory.createText(`export const op = '${node.operationId}'`)],
          }),
        ],
      }),
    ]
  },
})
```

### Generator methods

| Method         | Input                                   | Output                                | When to use                                                      |
| -------------- | ---------------------------------------- | -------------------------------------- | ------------------------------------------------------------------ |
| `schema()`     | `SchemaNode` (per data schema)          | `TElement \| Array<FileNode> \| void` | Generate types, validators, factories. Called once per schema    |
| `operation()`  | `OperationNode` (per API operation)     | `TElement \| Array<FileNode> \| void` | Generate hooks, clients, handlers. Called once per operation     |
| `operations()` | `Array<OperationNode>` (all operations) | `TElement \| Array<FileNode> \| void` | Generate index or barrel files. Called once after all operations |

### `GeneratorContext` properties (the `ctx` argument passed to each method)

| Property              | Type                                                | Purpose                                                              |
| --------------------- | ----------------------------------------------------| ---------------------------------------------------------------------|
| `ctx.config`          | `Config`                                            | Resolved Kubb configuration                                          |
| `ctx.root`            | `string`                                            | Absolute path to the output directory for the current plugin         |
| `ctx.options`         | `TResolvedOptions`                                  | Per-node resolved options (after exclude/include/override filtering) |
| `ctx.plugin`          | `Plugin`                                            | The owning plugin descriptor                                         |
| `ctx.resolver`        | `Resolver`                                          | Resolver for the current plugin                                      |
| `ctx.driver`          | `KubbDriver`                                        | Plugin driver for cross-plugin access                                |
| `ctx.hooks`           | `Hookable<KubbHooks>`                               | Event bus for `KubbHooks` events                                     |
| `ctx.adapter`         | `Adapter`                                           | The adapter that parsed the input spec                               |
| `ctx.meta`            | `InputMeta`                                         | Document metadata from the adapter. Carries `title`, `version`, `baseURL`, and the pre-computed `circularNames` and `enumNames` arrays. |
| `ctx.addFile()`       | `(...files: FileNode[]) => Promise<void>`           | Add files, skipping any that already exist                           |
| `ctx.upsertFile()`    | `(...files: FileNode[]) => Promise<void>`           | Add or merge files (concatenates sources and imports)                |
| `ctx.getPlugin()`     | `(name: string) => Plugin \| undefined`             | Get a plugin by name                                                 |
| `ctx.requirePlugin()` | `(name: string) => Plugin`                          | Get a plugin by name or throw a descriptive error                    |
| `ctx.getResolver()`   | `(name: string) => Resolver`                        | Get a resolver by plugin name                                        |
| `ctx.info()`          | `(message: string) => void`                         | Emit an info message via the build event system                      |
| `ctx.warn()`          | `(message: string) => void`                         | Emit a warning via the build event system                            |
| `ctx.error()`         | `(error: string \| Error) => void`                  | Emit an error via the build event system                             |

> [!TIP]
> Return an empty array `[]` to skip a node without error. Return `void` to handle file writing manually via `ctx.upsertFile()`.

### Related

- [Generator concepts](/docs/5.x/guide/concepts/generators)
- [AST concepts](/docs/5.x/guide/concepts/ast) for node types and traversal
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)
