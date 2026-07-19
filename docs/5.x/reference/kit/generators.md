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

### Scoping with `match` {#match}

Add a `match(node, ctx)` predicate to skip `schema` or `operation` for nodes a generator does not apply to. When `match` returns `false`, the engine skips that node entirely: no context work beyond what it already builds per node, and no call to `schema`/`operation`. Omitting `match` runs the generator for every node. `match` does not gate `operations()`, which already runs once on the full batch rather than per node.

This is useful when a plugin registers several generators for the same node type and only one should run per node, for example one hook generator per query variant in `@kubb/plugin-react-query`. Without `match`, every generator runs for every node and has to classify and bail out on its own.

```typescript twoslash [scoped-generator.ts]
import { ast, defineGenerator } from 'kubb/kit'

const getOnlyGenerator = defineGenerator({
  name: 'get-only-generator',
  match(node, ctx) {
    return ast.isHttpOperationNode(node) && node.method.toLowerCase() === 'get'
  },
  operation(node, ctx) {
    // node is already known to be a GET operation here
    return null
  },
})
```

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

### Related

- [Generator concepts](/docs/5.x/guide/concepts/generators)
- [AST concepts](/docs/5.x/guide/concepts/ast) for node types and traversal
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)
