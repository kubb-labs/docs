---
layout: doc
title: Resolvers - How Kubb Names Generated Files
description: A resolver is the single source of truth for a plugin's file names and output paths. Other plugins read it by name so they can import each other's output without hard-coding paths.
outline: deep
---

# Resolvers

A resolver answers two questions for every file a plugin emits: its name and its path. Every plugin has one. When a generator needs a file name or an import path, it asks the resolver instead of building the string itself, so names and paths stay in one place and stay consistent across the plugin's output.

<FlowDiagram preset="resolver" />

## Why naming is centralized

Plugins depend on each other's output. A React Query hook imports the types from `@kubb/plugin-ts` and the schemas from `@kubb/plugin-zod`. If each plugin invented file names inline, that coupling would break the moment one of them changed a casing rule. The resolver removes the guesswork. A plugin reads another plugin's resolver with `ctx.getResolver('plugin-ts')` and gets the exact names that plugin will emit, so the import always points at the right file.

Centralizing naming also gives users one place to override it. Setting `name` or a namespace method on a plugin's resolver changes every file that plugin writes, without touching the generators.

## What a resolver controls

The resolver owns identifier casing, the base file name including its extension, and the output path, with optional subdirectories per tag or per operation path. It also resolves cross-references: [`resolver.imports`](/docs/5.x/reference/kit/resolvers#imports) turns every `$ref` in a schema tree into an import entry that follows those same naming conventions.

Built-in defaults handle all of this, and they sit under `resolver.default` so an override can fall back to the original behavior instead of reimplementing it. Plugins that emit more than one symbol per node add namespaced methods on top, such as `query.name` or `response.status`.
