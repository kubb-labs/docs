---
layout: doc
title: Generators - How a Plugin Turns the AST Into Files
description: A generator is the piece of a plugin that walks the AST and emits files. One plugin can register several, each handling schemas, single operations, or the whole operation set.
outline: deep
---

# Generators

A generator is where a plugin produces code. The plugin handles options, lifecycle, and wiring, while the generator reads a node from the [AST](/docs/5.x/guide/concepts/ast) and returns the files that node becomes. A plugin with no generators emits nothing.

<FlowDiagram preset="generator" />

## Why a plugin splits into generators

You could write one big function, but most plugins produce several kinds of output from the same spec. `@kubb/plugin-react-query` writes a hook per operation, a query key per operation, and a barrel once everything is done. Splitting that into named generators keeps each one small and lets the engine call the right generator for each node, instead of one function branching on everything it might see.

A plugin registers its generators during [plugin setup](/docs/5.x/guide/concepts/plugins). After that, the engine owns the schedule, walking the AST once and calling each generator's methods as the matching nodes come up.

## What each method handles

A generator implements up to three methods, and each maps to a slice of the spec:

- `schema` runs once per data schema. It is where types, validators, and mock factories come from.
- `operation` runs once per API operation. It builds request hooks, clients, and route handlers.
- `operations` runs a single time with the whole set at once. Reach for it when an index or a router has to see every operation before it writes anything.

Each method receives the generator context and returns the files that node becomes. It can hand back file nodes directly, return a renderer element, or write through the context and return nothing. The [generator reference](/docs/5.x/reference/kit/generators) lists every field on that context.

## Scoping a generator with `match`

A plugin sometimes registers several generators for the same node type, where only one should run per node, for example one hook generator per query variant. Give a generator a `match(node, ctx)` predicate to declare that scope: when it returns `false`, the engine skips `schema` or `operation` for that node entirely, instead of calling the generator only to have it classify the node and bail out itself. See the [generator reference](/docs/5.x/reference/kit/generators#match) for the full signature.
