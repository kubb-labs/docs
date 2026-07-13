---
layout: doc
title: Kit - The Plugin Authoring Toolkit
description: kubb/kit groups definePlugin, defineGenerator, createResolver, defineParser, createAdapter, createRenderer, the ast namespace, and the factory node builders behind one import, kept apart from the engine that runs them.
outline: deep
---

# Kit: the plugin authoring toolkit

`kubb/kit` contains everything you need to create your own plugin and custom logic. A plugin, a generator, a resolver, a parser, or a custom adapter or renderer all start from this one import. See [Architecture](/docs/5.x/guide/concepts/architecture) for where kit sits in the pipeline, [Plugins](/docs/5.x/guide/concepts/plugins) for what a plugin does once it is built, and [AST](/docs/5.x/guide/concepts/ast) for the tree kit's `ast` namespace wraps.

## Why a separate surface from the engine

The Kubb engine also runs the build: the plugin driver, the file manager, the CLI reporters. None of that is part of authoring a plugin. A plugin author calls `definePlugin` and returns an object. The engine discovers that object, walks the AST against it, and writes the result to disk. Mixing the two into one import would mean every plugin author pulls in driver internals they never call.

Kit keeps the two apart the same way the AST layer and the JSX renderer stay separate from the engine that drives them. You call `kubb/kit` to build things. The engine, reached through the `kubb` package and its CLI, runs them.
