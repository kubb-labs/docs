---
layout: doc
title: Kit - The Plugin Authoring Toolkit
description: kubb/kit groups definePlugin, defineGenerator, defineResolver, defineParser, createAdapter, createRenderer, the ast namespace, and the factory node builders behind one import, kept apart from the engine that runs them.
outline: deep
---

# Kit: the plugin authoring toolkit

`kubb/kit` is what you import to author a plugin, a generator, a resolver, a parser, or a custom adapter or renderer. It groups `definePlugin`, `defineGenerator`, `defineResolver`, `defineParser`, `createAdapter`, `createRenderer`, the `ast` namespace and `factory` node builders you use to construct output, and the option and hook types that go with all of it. See [Architecture](/docs/5.x/guide/concepts/architecture) for where kit sits in the pipeline, [Plugins](/docs/5.x/guide/concepts/plugins) for what a plugin does once it is built, and [AST](/docs/5.x/guide/concepts/ast) for the tree kit's `ast` namespace wraps.

## Why a separate surface from the engine

`@kubb/core` also runs the build engine: the plugin driver, the file manager, the CLI reporters. None of that is part of authoring a plugin. A plugin author calls `definePlugin` and returns an object. The engine discovers that object, walks the AST against it, and writes the result to disk. Mixing the two into one import would mean every plugin author pulls in driver internals they never call.

Kit keeps the two apart the same way `kubb/ast` and `kubb/jsx` separate the AST layer and the JSX renderer from the engine that drives them. You call `kubb/kit` to build things. The engine, reached through the `kubb` package and its CLI, runs them.

## Why ast and factory live in kit, not kubb/ast

Node building is the most common thing a generator author does. Nearly every `operation` or `schema` handler ends with a call to `ast.factory.createFile` or one of its neighbors, so the node builders sit right next to `definePlugin` and `defineGenerator` instead of requiring a second import from `kubb/ast`.

`kubb/ast` still holds everything else: the guards, the macros, the schema and string helpers, the dialect, the printer, and the visitors. Import from there directly when you are working with the AST outside of a plugin, say a macro or a script that narrows a node on its own. Inside a plugin or generator, pull `ast` from kit instead, since you already import `definePlugin` or `defineGenerator` from the same place.

## Reference

The full list of exports, `definePlugin`, `defineGenerator`, `defineResolver`, `defineParser`, `createAdapter`, `createRenderer`, `createStorage`, `Diagnostics`, `memoryStorage`, `fsStorage`, the `ast` and `factory` namespaces, and the `kubb/kit/testing` helpers, lives in the [Kit API reference](/docs/5.x/reference/kit).

See also [Plugins](/docs/5.x/guide/concepts/plugins) for the plugin lifecycle, [AST](/docs/5.x/guide/concepts/ast) for the tree kit's `ast` namespace wraps, and [Creating your first plugin](/docs/5.x/guide/going-further/creating-plugins) for a step-by-step build.
