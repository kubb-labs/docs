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

Centralizing naming also gives you one place to override it. Change a rule on a plugin's resolver and every file that plugin writes follows the new rule, without touching its generators.

## What a resolver controls

A resolver owns the rules behind both of those questions:

- The casing of each generated identifier.
- The file name it lands in.
- The folder that file goes to, with optional subdirectories per tag or operation path.

It also turns every `$ref` in a schema into an import that follows those same rules, so a generated file points at its dependencies by the names their owners actually use.

Kubb ships defaults for all of this, so a plugin overrides only the rules it cares about and inherits the rest. See the [resolver reference](/docs/5.x/reference/kit/resolvers) for the defaults and the override API.
