---
layout: doc
title: AST - Universal Tree for Specs and Generators
description: Build, walk, transform, and collect Kubb's universal Abstract Syntax Tree. The AST decouples input formats like OpenAPI from generators so plugins stay spec-agnostic.
outline: deep
---

# AST

The `@kubb/ast` package defines Kubb's universal Abstract Syntax Tree. [Adapters](/docs/5.x/concepts/adapters) produce it from a specification (OpenAPI, AsyncAPI, JSON Schema, …), and [plugins](/docs/5.x/concepts/plugins) consume it to emit files. Because every plugin reads the same AST, the same plugin works against any spec a custom adapter can supply.

> [!NOTE]
> `@kubb/core` re-exports `@kubb/ast` as the `ast` namespace. Most plugins do not need to add `@kubb/ast` as a direct dependency. Install it explicitly only when you want named imports without the `ast.` prefix.

## Quick start

The complete public surface lives behind a handful of factories, three visitors, and a small set of guards:

```typescript twoslash [example.ts]
import { createInput, createOperation, createSchema, walk, transform, collect, isSchemaNode, narrowSchema } from '@kubb/ast'
import type { InputNode, OperationNode, SchemaNode } from '@kubb/ast'

const root: InputNode = createInput({
  schemas: [createSchema({ name: 'Pet', type: 'object', properties: [] })],
  operations: [createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

## Tree shape

A single [`InputNode`](https://github.com/kubb-labs/kubb/blob/main/packages/ast/src/nodes/root.ts#L47) sits at the top, containing reusable schemas and operations. Operations point at parameters, an optional request body, and responses. Each of those connects back to schemas.

```text
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

Request bodies and responses hold one `ContentNode` per content type (for example `application/json`), and each content node carries its own body schema. Every child slot in the tree is a node, so a single traversal table drives `walk`, `transform`, and `collect` across the whole tree.

Every node carries a `kind` field as the discriminant, so `switch (node.kind)` narrows the type for you.

> [!TIP]
> The AST is **spec-agnostic**. Plugins never look at OpenAPI directly. They consume the AST produced by the [adapter](/docs/5.x/concepts/adapters), which lets the same plugin work for OpenAPI 2.0, 3.0, 3.1, and any custom adapter alike.

An `OperationNode` is a discriminated union keyed on `protocol`, so the model stays spec-neutral while keeping HTTP details fully typed. An `HttpOperationNode` (`protocol: 'http'`) guarantees a non-nullable `method` (an `HttpMethod`) and `path`. A `GenericOperationNode` describes a non-HTTP transport and omits both. `@kubb/adapter-oas` produces `HttpOperationNode`s, so OpenAPI output is unchanged.

> [!TIP]
> Narrow before you read transport details. Call `isHttpOperationNode(node)` (or check `node.protocol === 'http'`) to turn an `OperationNode` into an `HttpOperationNode`, after which `method` and `path` are guaranteed:
>
> ```ts
> import { isHttpOperationNode } from '@kubb/ast'
>
> if (isHttpOperationNode(node)) {
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

Factories return correctly defaulted, fully typed nodes. Use them in adapters and inside generator handlers. Never construct AST literals by hand.

```typescript twoslash [factories.ts]
import { createInput, createOperation, createSchema } from '@kubb/ast'

const root = createInput({
  schemas: [createSchema({ name: 'Pet', type: 'object', properties: [] }), createSchema({ name: 'Status', type: 'enum', values: ['active', 'inactive'] })],
  operations: [createOperation({ operationId: 'listPets', method: 'GET', path: '/pets' })],
})
```

`@kubb/ast` also exports factories for source files and TypeScript-level artifacts that generators emit:

| Factory                                                             | Purpose                                                  |
| ------------------------------------------------------------------- | -------------------------------------------------------- |
| `createFile`, `createSource`, `createText`                          | Build `FileNode`s emitted by generators.                 |
| `createImport`, `createExport`                                      | Emit `import` / `export` statements.                     |
| `createConst`, `createFunction`, `createArrowFunction`, `createJsx` | Emit TypeScript declarations and JSX.                    |
| `createFunctionParameter`, `createFunctionParameters`               | Build typed function parameter lists.                    |
| `createParameter`, `createParameterGroup`, `createParamsType`       | Describe operation parameters.                           |
| `createProperty`, `createType`                                      | Compose object properties and TypeScript types.          |
| `createResponse`, `createRequestBody`, `createContent`, `createOutput` | Model responses, request bodies, content entries, and generator outputs. |
| `createBreak`                                                       | Emit line breaks.                                        |
| `update`                                                            | Apply an identity-preserving shallow update to any node. |

## Visitors

Three visitor functions cover the common traversal patterns. Visitor objects use lowercase, kind-style keys (`input`, `operation`, `schema`, `property`, `parameter`, `response`).

### `walk`: async traversal with side effects

```typescript twoslash [walk.ts]
import { createInput, walk } from '@kubb/ast'

const root = createInput({ schemas: [], operations: [] })

await walk(root, {
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

**Use when:** logging, validating, collecting statistics, or triggering side effects per node.

### `transform`: synchronous, returns a new tree

```typescript twoslash [transform.ts]
import { createInput, transform } from '@kubb/ast'

const root = createInput({ schemas: [], operations: [] })

const enhanced = transform(root, {
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

**Use when:** modifying AST structure, normalizing inconsistencies, or annotating nodes.

> [!NOTE]
> `transform` preserves identity (structural sharing). When a visitor leaves a node and all of its descendants unchanged, `transform` returns the original reference, so unchanged subtrees and their arrays are reused, not copied. Returning the same node from a visitor is a no-op. Returning a new node replaces it and rebuilds only its ancestors. A no-op pass therefore allocates nothing, and you can detect whether anything changed with `result === input`.

To apply a change while keeping that guarantee, use the `update` factory instead of spreading by hand. It returns the same node when every field you pass already matches:

```typescript twoslash [update.ts]
import { createSchema, update } from '@kubb/ast'

const node = createSchema({ name: 'Pet', type: 'object', properties: [] })

update(node, { name: 'Pet' }) // -> same `node` reference (no change)
update(node, { name: 'Animal' }) // -> new node with `name` replaced
```

### `collect`: gather matching nodes

```typescript twoslash [collect.ts]
import { createInput, collect } from '@kubb/ast'
import type { OperationNode, SchemaNode } from '@kubb/ast'

const root = createInput({ schemas: [], operations: [] })

const mutations = collect<OperationNode>(root, {
  operation(node) {
    return node.method === 'POST' ? node : undefined
  },
})

const deprecated = collect<SchemaNode>(root, {
  schema(node) {
    return 'deprecated' in node && node.deprecated ? node : undefined
  },
})

console.log(`POST operations: ${mutations.length}`)
console.log(`Deprecated schemas: ${deprecated.length}`)
```

**Use when:** finding specific nodes, filtering by criteria, building lists for further processing.

## Guards and narrowing

`@kubb/ast` exports type guards and a `narrowSchema` helper for safe discrimination:

```typescript twoslash [guards.ts]
import { isInputNode, isOperationNode, isOutputNode, isSchemaNode, narrowSchema, walk, createInput } from '@kubb/ast'

const root = createInput({ schemas: [], operations: [] })

await walk(root, {
  async schema(node) {
    if (!isSchemaNode(node)) return

    const obj = narrowSchema(node, 'object')
    if (obj) {
      console.log(`object with ${obj.properties.length} properties`)
    }

    if (node.type === 'ref') {
      console.log(`reference to: ${node.ref}`)
    }
  },
})

console.log(isInputNode(root)) // true
console.log(isOperationNode(root)) // false
console.log(isOutputNode(root)) // false
```

## Refs and naming helpers

The ref and naming helpers live in the `@kubb/ast/utils` subpath, together with the other string and code-building utilities. `collectImports` stays in the main package because it operates on AST nodes.

| Helper              | Import from       | Purpose                                             |
| ------------------- | ----------------- | --------------------------------------------------- |
| `extractRefName`    | `@kubb/ast/utils` | Turn `'#/components/schemas/Pet'` into `'Pet'`.     |
| `childName`         | `@kubb/ast/utils` | Derive a child property name from context.          |
| `enumPropName`      | `@kubb/ast/utils` | Convert an enum value into a valid property name.   |
| `findDiscriminator` | `@kubb/ast/utils` | Locate a discriminator on a `oneOf`/`union` schema. |
| `collectImports`    | `@kubb/ast`       | Collect imports required by a schema subtree.       |

```typescript twoslash [refs.ts]
import { extractRefName } from '@kubb/ast/utils'

const name = extractRefName('#/components/schemas/Pet')
//    ^?
```

## Constants

| Export        | Purpose                                    |
| ------------- | ------------------------------------------ |
| `schemaTypes` | Map of every schema `type` discriminant.   |

## Transformers

Structural rewrites you can apply inside `transform` to normalize schemas:

| Export                     | Purpose                                           |
| -------------------------- | ------------------------------------------------- |
| `mergeAdjacentObjectsLazy` | Collapse neighboring object schemas into one.     |
| `setDiscriminatorEnum`     | Attach a discriminator enum to union members.     |
| `setEnumName`              | Name an anonymous enum schema.                    |
| `simplifyUnion`            | Remove duplicates and dead branches from a union. |

## Dispatch

`dispatch` walks an ordered table of rules and returns the first node a rule produces. Adapters use it to map a source spec's shapes onto AST nodes without a sprawling `if`/`else` chain: each rule pairs a `match` predicate with a `convert` function, and rules are tried top to bottom.

```typescript twoslash [dispatch.ts]
import { dispatch, createSchema } from '@kubb/ast'
import type { DispatchRule } from '@kubb/ast'

type Ctx = { type: string; nullable: boolean }

const rules: Array<DispatchRule<Ctx, ReturnType<typeof createSchema>>> = [
  { name: 'string', match: (ctx) => ctx.type === 'string', convert: () => createSchema({ type: 'string' }) },
  { name: 'number', match: (ctx) => ctx.type === 'number', convert: () => createSchema({ type: 'number' }) },
]

const node = dispatch(rules, { type: 'string', nullable: false }) ?? createSchema({ type: 'any' })
```

Order is significant, so list higher-precedence shapes first. A rule whose `match` returns `true` may still `convert` to `null` to defer to the next rule (useful when a broad predicate, such as "has a `format`", only handles some values). `dispatch` returns `null` when no rule produces a node, leaving the caller to apply its own fallback. See [Concepts: Adapters](/docs/5.x/concepts/adapters) for how an adapter builds its schema table on top of this.

## Printers

Lower-level helpers for parsers that turn the AST into source code:

| Export                 | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `definePrinter`        | Typed helper for creating a `Printer`.              |
| `createPrinterFactory` | Build a factory that produces printers for plugins. |

See [Concepts: Parsers](/docs/5.x/concepts/parsers) for how parsers consume printers.

## Examples

### Collect every operation tag

```typescript twoslash [tags.ts]
import { createInput, collect } from '@kubb/ast'

const root = createInput({ schemas: [], operations: [] })

const tags = new Set(
  collect<string>(root, {
    operation(node) {
      return node.tags?.[0]
    },
  }),
)

console.log([...tags])
```
