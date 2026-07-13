---
layout: doc
title: Generators - How a Plugin Turns the AST Into Files
description: A generator is the piece of a plugin that walks the AST and emits files. One plugin can register several, each handling schemas, single operations, or the whole operation set.
outline: deep
---

# Generators

A generator is where a plugin actually produces code. The plugin handles naming, options, and lifecycle. The generator does the narrower job of reading a node from the [AST](/docs/5.x/guide/concepts/ast) and returning the files that node should become. A plugin with no generators emits nothing.

<FlowDiagram preset="generator" />

## Why a plugin splits into generators

You could write one big function, but most plugins produce several kinds of output from the same spec. `@kubb/plugin-react-query` writes a hook per operation, a query key per operation, and a barrel once everything is done. Splitting that into named generators keeps each one small, and it lets the engine call the right generator for each node instead of asking a single function to branch on everything it might see.

A plugin registers its generators in `kubb:plugin:setup` with `addGenerator`. After that the engine owns the schedule. It walks the AST once and calls each generator's methods as the matching nodes come up.

## What each method handles

A generator implements up to three methods, and each maps to a slice of the spec.

`schema` runs once per data schema, so it is where types, validators, and mock factories come from. `operation` runs once per API operation, which is where request hooks, clients, and route handlers get built. `operations` runs a single time with the whole set at once, which is what you want for an index or a router that has to see every operation before it writes anything.

Each method receives the generator context and returns the files that node becomes. It can hand back file nodes directly, return a renderer element, or write through the context and return nothing. The [generator reference](/docs/5.x/reference/kit/generators) lists every field on that context.
