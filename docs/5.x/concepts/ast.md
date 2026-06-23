---
layout: doc
title: AST - Universal Tree for Specs and Generators
description: Build, walk, transform, and collect Kubb's universal Abstract Syntax Tree. The AST decouples input formats like OpenAPI from generators so plugins stay spec-agnostic.
outline: deep
---

# AST

The `@kubb/ast` package defines Kubb's universal Abstract Syntax Tree. [Adapters](/docs/5.x/concepts/adapters) produce it from a specification (OpenAPI, AsyncAPI, JSON Schema, and so on), and [plugins](/docs/5.x/concepts/plugins) consume it to emit files. Because every plugin reads the same AST, one plugin works against any spec a custom adapter supplies.

> [!NOTE]
> `@kubb/core` re-exports `@kubb/ast` as the `ast` namespace, with node constructors under `ast.factory` the way TypeScript groups them under `ts.factory`. Most plugins do not need `@kubb/ast` as a direct dependency. Install it only for named imports without the `ast.` prefix, taking constructors from the `@kubb/ast/factory` subpath.

## Quick start

The public surface is a handful of factories, three visitors, and a few guards:

```typescript twoslash [example.ts]
import { ast } from '@kubb/core'

const root: ast.InputNode = ast.factory.createInput({
  schemas: [ast.factory.createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [ast.factory.createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

## Tree shape

A single [`InputNode`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/root.ts#L47) sits at the top, holding reusable schemas and operations. Operations point at parameters, an optional request body, and responses. Each of those connects back to schemas.

```text [Resulting tree]
InputNode
├── schemas: SchemaNode[]            (named, reusable schemas)
└── operations: OperationNode[]
    ├── parameters: ParameterNode[]  → SchemaNode
    ├── requestBody?: RequestBodyNode  → content: ContentNode[] → SchemaNode
    └── responses: ResponseNode[]      → content: ContentNode[] → SchemaNode

SchemaNode (discriminated by `type`)
  Structural:  object | array | tuple | union | intersection | enum
  Scalar:      string | number | integer | bigint | boolean
                null | any | unknown | void | never
  Special:     ref | date | datetime | time | uuid | email | url | blob
```

Request bodies and responses hold one `ContentNode` per content type (for example `application/json`), and each content node carries its own body schema. Every child slot is a node, so a single traversal table drives `walk`, `transform`, and `collect` across the whole tree.

Every node carries a `kind` field as the discriminant, so `switch (node.kind)` narrows the type for you.

> [!TIP]
> The AST is spec-agnostic. Plugins never look at OpenAPI directly. They read the AST the [adapter](/docs/5.x/concepts/adapters) produces, which is why one plugin works for OpenAPI 2.0, 3.0, 3.1, and any custom adapter.

An `OperationNode` is a discriminated union keyed on `protocol`, so the model stays spec-neutral while keeping HTTP details typed. An `HttpOperationNode` (`protocol: 'http'`) guarantees a non-nullable `method` (an `HttpMethod`) and `path`. A `GenericOperationNode` describes a non-HTTP transport and omits both. `@kubb/adapter-oas` produces `HttpOperationNode`s, so OpenAPI output is unchanged.

> [!TIP]
> Narrow before you read transport details. Call `isHttpOperationNode(node)` (or check `node.protocol === 'http'`) to turn an `OperationNode` into an `HttpOperationNode`. After that, `method` and `path` are guaranteed:
>
> ```ts
> import { ast } from '@kubb/core'
>
> if (ast.isHttpOperationNode(node)) {
>   console.log(node.method, node.path) // both are non-nullable here
> }
> ```

## Schema node types

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

The `@kubb/ast/factory` subpath also provides constructors for source files and TypeScript-level artifacts that generators emit:

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

Three visitor functions cover the common traversal patterns. Visitor objects use lowercase, kind-style keys (`input`, `operation`, `schema`, `property`, `parameter`, `response`). To rewrite nodes inside a plugin, reach for [macros](/docs/5.x/concepts/macros). They add names, ordering, and composition on top of `transform`.

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
| `findDiscriminator` | `@kubb/ast/utils` | Locate a discriminator on a `oneOf`/`union` schema. |

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

A macro is a named, composable transform built on `transform`. Macros rewrite nodes before printing, with ordering, gating, and reuse that a bare visitor does not give you. See [Concepts: Macros](/docs/5.x/concepts/macros).

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

See [Concepts: Parsers](/docs/5.x/concepts/parsers) for how parsers consume printers.

`defineDialect` is the adapter seam for spec-specific schema behavior. It keeps the shared converters generic, so an adapter supplies only the questions that differ between specs. See [Adapters](/docs/5.x/concepts/adapters#schema-dispatch-and-dialects).

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
