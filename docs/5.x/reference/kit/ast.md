---
layout: doc
title: AST and node builders
description: The ast namespace groups the factory node builders, the transform and collect visitors, the guards, the ref and naming helpers, the macro engine, and the printer helper behind one import.
outline: [2, 3]
---

# AST and node builders

## `ast`

`ast` is `kubb/kit`'s namespace for the entire AST surface, the same way TypeScript groups its node constructors under `ts.factory`. It carries the `factory` node builders, the `transform` and `collect` visitors, the guards, the ref and string helpers, and the macro engine.

```typescript twoslash [ast-namespace.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [],
})
```

Node building goes through `ast.factory`. `ast.factory.createFile`, `ast.factory.createSource`, and `ast.factory.createText` build the `FileNode` tree a generator returns.

```typescript twoslash [factory.ts]
import { ast } from 'kubb/kit'

const file = ast.factory.createFile({
  baseName: 'pet.ts',
  path: './pet.ts',
  sources: [ast.factory.createSource({ nodes: [ast.factory.createText('export type Pet = { id: number }')] })],
})
```

For why the AST exists and how it fits the pipeline, see [AST concepts](/docs/5.x/guide/concepts/ast).

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

Factories return defaulted, fully typed nodes for adapters and generator handlers. Never build AST literals by hand.

```typescript twoslash [factories.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] }), ast.factory.createSchema({ name: 'Status', type: 'enum', values: ['active', 'inactive'] })],
  operations: [ast.factory.createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

The `ast.factory` namespace also provides constructors for source files and TypeScript-level artifacts that generators emit:

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

## Visitors {#visitors}

Two visitor functions cover the common traversal patterns: `transform` rewrites the tree and `collect` gathers nodes. Visitor objects use lowercase, kind-style keys (`input`, `operation`, `schema`, `property`, `parameter`, `response`). To rewrite nodes inside a plugin, reach for [macros](/docs/5.x/guide/going-further/macros), which add names, ordering, and composition on top of `transform`. For logging, validation, or statistics, `collect` the nodes you care about.

### `transform`: synchronous, returns a new tree

```typescript twoslash [transform.ts]
import { ast } from 'kubb/kit'

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

To apply a change and keep that guarantee, use the `update` factory instead of spreading by hand. It returns the same node when every field you pass already matches:

```typescript twoslash [update.ts]
import { ast } from 'kubb/kit'

const node = ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })

ast.factory.update(node, { name: 'Pet' }) // -> same `node` reference (no change)
ast.factory.update(node, { name: 'Animal' }) // -> new node with `name` replaced
```

### `collect`: gather matching nodes

```typescript twoslash [collect.ts]
import { ast } from 'kubb/kit'

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

## Guards and narrowing {#guards-and-narrowing}

Kubb exports type guards and a `narrowSchema` helper for safe discrimination:

```typescript twoslash [guards.ts]
import { ast } from 'kubb/kit'

const root = ast.factory.createInput({ schemas: [], operations: [] })

for (const node of ast.collect<ast.SchemaNode>(root, { schema: (node) => node })) {
  const obj = ast.narrowSchema(node, 'object')
  if (obj) {
    console.log(`object with ${obj.properties.length} properties`)
  }

  if (node.type === 'ref') {
    console.log(`reference to: ${node.ref}`)
  }
}

for (const node of ast.collect<ast.OperationNode>(root, { operation: (node) => node })) {
  if (ast.isHttpOperationNode(node)) {
    console.log(`${node.method} ${node.path}`)
  }
}
```

## Refs and naming helpers

The ref and naming helpers split across two surfaces. `resolveRefName` ships on the `ast` namespace, like the guards and node types. `extractRefName`, `childName`, `enumPropName`, and `syncSchemaRef` are named exports of `kubb/kit` itself, not members of the `ast` namespace (the same split as the built-in macros below).

| Helper           | Purpose                                                             |
| ---------------- | ------------------------------------------------------------------- |
| `extractRefName` | Turn `'#/components/schemas/Pet'` into `'Pet'`.                     |
| `resolveRefName` | Resolve the name a ref node emits, preferring its `targetName`.     |
| `childName`      | Derive a child property name from context.                          |
| `enumPropName`   | Convert an enum value into a valid property name.                   |
| `syncSchemaRef`  | Merge a ref node with its resolved schema, letting usage-site fields (`description`, `nullable`) override. |

```typescript twoslash [refs.ts]
import { extractRefName } from 'kubb/kit'

const name = extractRefName('#/components/schemas/Pet')
//    ^?
```

## Schema graph

Analyze how schemas reference each other, to prune unused schemas or wrap circular ones in a lazy construct. `collectUsedSchemaNames` and `findCircularSchemas` ship on the `ast` namespace. `containsCircularRef` is a named export of `kubb/kit` itself, not a member of the `ast` namespace.

| Helper                   | Purpose                                                                                            |
| ------------------------ | ------------------------------------------------------------------------------------------------- |
| `collectUsedSchemaNames` | Collect the names of every top-level schema transitively used by a set of operations. Pair it with `include` filters to leave unreferenced schemas ungenerated. |
| `findCircularSchemas`    | Find every schema that takes part in a circular dependency chain, so those positions can be wrapped in a lazy getter or `z.lazy(() => …)`. |
| `containsCircularRef`    | Report whether a schema, or anything nested inside it, references a circular schema. Import it from `kubb/kit` directly, not through `ast`.  |

## Constants

| Export        | Purpose                                    |
| ------------- | ------------------------------------------ |
| `schemaTypes` | Map of every schema `type` discriminant.   |

## Macros

A macro is a named, composable transform built on `transform` that rewrites nodes before printing, adding ordering, gating, and reuse a bare visitor doesn't give you. See [Macros concepts](/docs/5.x/guide/going-further/macros).

| Export          | Purpose                                          |
| --------------- | ------------------------------------------------ |
| `defineMacro`   | Type a macro and read it as one definition.      |
| `composeMacros` | Fold an ordered list of macros into one visitor. |
| `applyMacros`   | Run a list of macros over a node tree.           |

Kubb also ships built-in macros for common schema normalizations that any adapter can compose with its own. These are named exports of `kubb/kit` itself, not members of the `ast` namespace. See [Built-in macros](/docs/5.x/guide/going-further/macros#built-in-macros) for the full walkthrough.

| Macro                    | Purpose                                                                                     |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| `macroSimplifyUnion`     | Drop union members a broader scalar primitive already covers, such as a multi-value string enum next to `string`. |
| `macroDiscriminatorEnum` | Replace a discriminator property's schema with a string enum of its allowed values.         |
| `macroEnumName`          | Name an inline enum schema from its parent and property name.                               |
| `macroRenameSchema`      | Rename a schema's declaration and retarget every ref pointing at it in one pass.            |

## Printers

Lower-level helpers for parsers that turn the AST into source code:

| Export          | Purpose                                |
| --------------- | -------------------------------------- |
| `createPrinter` | Typed helper for creating a `Printer`. |

`createPrinter` takes an `overrides` map to replace the handler for individual schema node types. Inside an override, `this.base(node)` runs the built-in handler the override replaced, so you can wrap its output instead of re-implementing it. Pass overrides through the `overrides` field rather than spreading them into `nodes`, otherwise `this.base` cannot find the original handler. The `printer.nodes` option on `@kubb/plugin-ts`, `@kubb/plugin-zod`, and `@kubb/plugin-faker` feeds this map. See [Override a printer](/docs/5.x/guide/going-further/printers).

See [Parsers concepts](/docs/5.x/guide/concepts/parsers) for how parsers consume printers.
