---
layout: doc
title: AST - Why Kubb Uses a Universal Tree
description: How Kubb's universal Abstract Syntax Tree decouples input formats like OpenAPI from the generators that emit code, so one plugin works against any spec.
outline: deep
---

# AST

Kubb's universal Abstract Syntax Tree is the contract between the two halves of the pipeline. [Adapters](/docs/5.x/guide/concepts/adapters) produce the AST from a specification (OpenAPI, AsyncAPI, JSON Schema, and so on), and [plugins](/docs/5.x/guide/concepts/plugins) consume it to emit files. Because every plugin reads the same tree, one plugin works against any spec a custom adapter supplies.

## The tree shape

A single `InputNode` sits at the top, holding reusable schemas and operations. Operations point at parameters, an optional request body, and responses. Each of those connects back to schemas.

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
  Special:     ref | date | datetime | time | uuid | email | url | ipv4 | ipv6 | blob
```

Request bodies and responses hold one `ContentNode` per content type (for example `application/json`), and each content node carries its own body schema. Every child slot is a node, so a single traversal drives `walk`, `transform`, and `collect` across the whole tree. Every node also carries a `kind` field as the discriminant, so `switch (node.kind)` narrows the type for you.

## Spec-agnostic by design

The AST is the reason plugins stay simple. A plugin never looks at OpenAPI directly. It reads the tree the adapter produces, which is why one plugin works for OpenAPI 2.0, 3.0, 3.1, and any custom adapter.

Operations keep that neutrality even for transport details. An `OperationNode` is a discriminated union keyed on `protocol`, so the model stays spec-neutral while HTTP specifics stay typed. An `HttpOperationNode` (`protocol: 'http'`) guarantees a non-nullable `method` and `path`. A `GenericOperationNode` describes a non-HTTP transport and omits both. `@kubb/adapter-oas` produces `HttpOperationNode`s, so OpenAPI output is unchanged. Narrow with `isHttpOperationNode(node)` before reading `method` or `path`.

## How the AST connects the pipeline

The same tree flows through four stages, each documented on its own page:

- [Adapters](/docs/5.x/guide/concepts/adapters) build the AST from a spec.
- [Plugins](/docs/5.x/guide/concepts/plugins) read it and emit files.
- [Macros](/docs/5.x/guide/going-further/macros) rewrite nodes before printing.
- [Parsers](/docs/5.x/guide/concepts/parsers) turn the emitted nodes into source code.

> [!NOTE]
> The `ast` namespace and its `factory` node builders are not part of `kubb/ast`. They travel with the plugin authoring toolkit instead, so you import them from [`kubb/kit`](/docs/5.x/guide/concepts/kit) alongside `definePlugin` and `defineGenerator`. Everything else on this page, including the guards, the macros, the printer, and the visitors, comes from `kubb/ast` directly. See the [Kit API reference](/docs/5.x/reference/kit) for the full list.

## Reference

The callable surface lives in the [AST API reference](/docs/5.x/reference/ast): the `walk`, `transform`, and `collect` visitors, the type guards, and the naming helpers.
