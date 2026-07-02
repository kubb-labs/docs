---
layout: doc
title: AST API - Factories, Visitors, and Guards
description: The @kubb/ast surface. Node factories, the walk, transform, and collect visitors, type guards, naming helpers, and constants for working with Kubb's universal AST.
outline: deep
---

# AST API

`@kubb/ast` is the package behind Kubb's universal Abstract Syntax Tree. This page documents its callable surface: node factories, the three visitors, type guards, and helpers. For why the AST exists and how it fits the pipeline, see [AST concepts](/docs/5.x/guide/concepts/ast).

> [!NOTE]
> `@kubb/core` re-exports `@kubb/ast` as the `ast` namespace, with node constructors under `ast.factory` the way TypeScript groups them under `ts.factory`. Most plugins do not need `@kubb/ast` as a direct dependency. Install it only for named imports without the `ast.` prefix, taking constructors from the `factory` export of `@kubb/ast`.

## Quick start

The public surface is a handful of factories, three visitors, and a few guards:

```typescript twoslash [example.ts]
import { ast } from '@kubb/core'

const root: ast.InputNode = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [ast.factory.createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

## Schema node types

A `SchemaNode` is discriminated by its `type`. The values fall into three families.

### Structural types

| Type           | Description                             | TypeScript                      |
| -------------- | --------------------------------------- | ------------------------------- |
| `object`       | Object with named properties            | `{ name: string; age: number }` |
| `array`        | Sequence of items                       | `string[]`                      |
| `tuple`        | Fixed-length array with typed positions | `[string, number, boolean]`     |
| `union`        | One of multiple types                   | `string \| number`              |
| `intersection` | Combination of multiple types           | `A & B`                         |
| `enum`         | Fixed set of literal values             | `'active' \| 'inactive'`        |

### Scalar types

| Type      | Description    | TypeScript |
| --------- | -------------- | ---------- |
| `string`  | Text value     | `string`   |
| `number`  | Numeric value  | `number`   |
| `integer` | Whole number   | `number`   |
| `bigint`  | Large integer  | `bigint`   |
| `boolean` | True/false     | `boolean`  |
| `null`    | Null value     | `null`     |
| `any`     | Any value      | `any`      |
| `unknown` | Unknown value  | `unknown`  |
| `void`    | No value       | `void`     |
| `never`   | Never produced | `never`    |

### Special types

| Type       | Description                 | Example                                |
| ---------- | --------------------------- | -------------------------------------- |
| `ref`      | Reference to another schema | `Pet` (from `$ref`)                    |
| `date`     | ISO date                    | `2024-01-15`                           |
| `datetime` | ISO datetime                | `2024-01-15T10:30:00Z`                 |
| `time`     | ISO time                    | `10:30:00`                             |
| `uuid`     | UUID string                 | `550e8400-e29b-41d4-a716-446655440000` |
| `email`    | Email address               | `user@example.com`                     |
| `url`      | URL string                  | `https://example.com`                  |
| `blob`     | Binary data                 | Raw bytes                              |

## Factory functions

Factories return defaulted, fully typed nodes. Use them in adapters and inside generator handlers. Never build AST literals by hand.

```typescript twoslash [factories.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] }), ast.factory.createSchema({ name: 'Status', type: 'enum', values: ['active', 'inactive'] })],
  operations: [ast.factory.createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

The `factory` namespace also provides constructors for source files and TypeScript-level artifacts that generators emit:

| Factory                                                             | Purpose                                                  |
| ------------------------------------------------------------------- | -------------------------------------------------------- |
| `createFile`, `createSource`, `createText`                          | Build `FileNode`s emitted by generators.                 |
| `createImport`, `createExport`                                      | Emit `import` / `export` statements.                     |
| `createConst`, `createFunction`, `createArrowFunction`, `createJsx` | Emit TypeScript declarations and JSX.                    |
| `createParameter`                                                   | Describe operation parameters.                           |
| `createProperty`, `createType`                                      | Compose object properties and TypeScript types.          |
| `createResponse`, `createRequestBody`, `createContent`, `createOutput` | Model responses, request bodies, content entries, and generator outputs. |
| `createBreak`                                                       | Emit line breaks between nodes.                          |
| `update`                                                            | Apply an identity-preserving shallow update to any node. |

## Visitors

Three visitor functions cover the common traversal patterns. Visitor objects use lowercase, kind-style keys (`input`, `operation`, `schema`, `property`, `parameter`, `response`). To rewrite nodes inside a plugin, reach for [macros](/docs/5.x/guide/going-further/macros). They add names, ordering, and composition on top of `transform`.

### `walk`: async traversal with side effects

```typescript twoslash [walk.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({ schemas: [], operations: [] })

await ast.walk(root, {
  async operation(node) {
    console.log(`Found ${node.method} ${node.path}`)
  },
  async schema(node) {
    if ('deprecated' in node && node.deprecated) {
      console.warn(`Schema ${'name' in node ? node.name : '?'} is deprecated`)
    }
  },
})
```

Use `walk` to log, validate, collect statistics, or trigger a side effect per node.

### `transform`: synchronous, returns a new tree

```typescript twoslash [transform.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const enhanced = ast.transform(root, {
  schema(node) {
    if (node.type === 'object' && node.additionalProperties === undefined) {
      return { ...node, additionalProperties: false }
    }
    return node
  },
  operation(node) {
    return { ...node, tags: node.tags?.length ? node.tags : ['untagged'] }
  },
})
```

Use `transform` to change AST structure, normalize inconsistencies, or annotate nodes.

> [!NOTE]
> `transform` preserves identity through structural sharing. When a visitor leaves a node and all its descendants unchanged, `transform` returns the original reference, so unchanged subtrees and their arrays are reused, not copied. Returning the same node is a no-op. Returning a new node replaces it and rebuilds only its ancestors. A no-op pass allocates nothing, and you detect whether anything changed with `result === input`.

To apply a change and keep that guarantee, use the `update` factory instead of spreading by hand. It returns the same node when every field you pass already matches:

```typescript twoslash [update.ts]
import { ast } from '@kubb/core'

const node = ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })

ast.factory.update(node, { name: 'Pet' }) // -> same `node` reference (no change)
ast.factory.update(node, { name: 'Animal' }) // -> new node with `name` replaced
```

### `collect`: gather matching nodes

```typescript twoslash [collect.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const mutations = ast.collect<ast.OperationNode>(root, {
  operation(node) {
    return node.method === 'POST' ? node : undefined
  },
})

const deprecated = ast.collect<ast.SchemaNode>(root, {
  schema(node) {
    return 'deprecated' in node && node.deprecated ? node : undefined
  },
})

console.log(`POST operations: ${mutations.length}`)
console.log(`Deprecated schemas: ${deprecated.length}`)
```

Use `collect` to find specific nodes, filter by a criterion, or build a list for later processing.

## Guards and narrowing

`@kubb/ast` exports type guards and a `narrowSchema` helper for safe discrimination:

```typescript twoslash [guards.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({ schemas: [], operations: [] })

await ast.walk(root, {
  async schema(node) {
    const obj = ast.narrowSchema(node, 'object')
    if (obj) {
      console.log(`object with ${obj.properties.length} properties`)
    }

    if (node.type === 'ref') {
      console.log(`reference to: ${node.ref}`)
    }
  },
  async operation(node) {
    if (ast.isHttpOperationNode(node)) {
      console.log(`${node.method} ${node.path}`)
    }
  },
})
```

## Refs and naming helpers

The ref and naming helpers live in the `@kubb/ast/utils` subpath, alongside the other string and code-building utilities.

| Helper              | Import from       | Purpose                                             |
| ------------------- | ----------------- | --------------------------------------------------- |
| `extractRefName`    | `@kubb/ast/utils` | Turn `'#/components/schemas/Pet'` into `'Pet'`.     |
| `childName`         | `@kubb/ast/utils` | Derive a child property name from context.          |
| `enumPropName`      | `@kubb/ast/utils` | Convert an enum value into a valid property name.   |

```typescript twoslash [refs.ts]
import { extractRefName } from '@kubb/ast/utils'

const name = extractRefName('#/components/schemas/Pet')
//    ^?
```

## Constants

| Export        | Purpose                                    |
| ------------- | ------------------------------------------ |
| `schemaTypes` | Map of every schema `type` discriminant.   |

## Macros

A macro is a named, composable transform built on `transform`. Macros rewrite nodes before printing, with ordering, gating, and reuse that a bare visitor does not give you. See [Macros concepts](/docs/5.x/guide/going-further/macros).

| Export          | Purpose                                          |
| --------------- | ------------------------------------------------ |
| `defineMacro`   | Type a macro and read it as one definition.      |
| `composeMacros` | Fold an ordered list of macros into one visitor. |
| `applyMacros`   | Run a list of macros over a node tree.           |

## Printers

Lower-level helpers for parsers that turn the AST into source code:

| Export          | Purpose                                |
| --------------- | -------------------------------------- |
| `createPrinter` | Typed helper for creating a `Printer`. |

`createPrinter` takes an `overrides` map to replace the handler for individual schema node types. Inside an override, `this.base(node)` runs the built-in handler the override replaced, so you can wrap its output instead of re-implementing it. Pass overrides through the `overrides` field rather than spreading them into `nodes`, otherwise `this.base` cannot find the original handler.

See [Parsers concepts](/docs/5.x/guide/concepts/parsers) for how parsers consume printers. `defineDialect` is the adapter seam for spec-specific schema behavior. It keeps the shared converters generic, so an adapter supplies only the questions that differ between specs. See [Adapters](/docs/5.x/reference/adapters#schema-dispatch-and-dialects).

## Examples

### Collect every operation tag

```typescript twoslash [tags.ts]
import { ast } from '@kubb/core'

const root = ast.factory.createInput({ schemas: [], operations: [] })

const tags = new Set(
  ast.collect<string>(root, {
    operation(node) {
      return node.tags?.[0]
    },
  }),
)

console.log([...tags])
```
