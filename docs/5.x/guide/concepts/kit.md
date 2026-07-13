---
layout: doc
title: Kit - The Plugin Authoring Toolkit
description: kubb/kit is the authoring layer of Kubb. It is the one import a developer uses to build plugins, generators, resolvers, adapters, parsers, renderers, and storage backends, with the ast and core helpers those pieces lean on.
outline: deep
---

# Kit: the plugin authoring toolkit

`kubb/kit` is the layer you build on. Everything a developer writes to extend Kubb starts from this one import: your own plugin, the generators it runs, the resolver that names its files, and any adapter, parser, renderer, or storage backend you add. See the [Kit API reference](/docs/5.x/reference/kit) for the full surface, [Architecture](/docs/5.x/guide/concepts/architecture) for where kit sits in the pipeline, and [Plugins](/docs/5.x/guide/concepts/plugins) for what a plugin does once it is built.

## What you build with it

A plugin is the usual starting point. `definePlugin` gives you the lifecycle hooks, and `defineGenerator` gives you the handlers that walk the AST and emit files. Kit covers the rest of the surface a real plugin reaches for. `createResolver` decides what your files are called and where they land, so other plugins import your output by reading that resolver instead of guessing paths. `createAdapter` teaches Kubb a new input format, `defineParser` turns the emitted nodes into a source string, `createRenderer` walks a templating format into `FileNode`s, and `createStorage` sends the result somewhere other than the filesystem.

## AST helpers

Most generator handlers end by building a node, so the [`ast`](/docs/5.x/guide/concepts/ast) namespace sits in the same import. It ships the `factory` builders you call to construct output, the guards that narrow a node by its kind, the macros that rewrite a tree before it prints, the printers a parser drives, and the `transform` and `collect` visitors. Pull `ast` from `kubb/kit` whether you are inside a plugin or writing a standalone script that reads a spec on its own.

## Core helpers

The same import carries the helpers that belong to no single plugin. `Diagnostics` builds and narrows the structured errors Kubb collects during a build, and `kubb/kit/testing` gives you Vitest-backed helpers for exercising a plugin, generator, or adapter without running a full build.

## Why a separate surface from the engine

The Kubb engine also runs the build: the plugin driver, the file manager, the CLI reporters. None of that is part of authoring a plugin. You call `definePlugin` and return an object. The engine discovers that object, walks the AST against it, and writes the result to disk. Folding the two into one import would hand every plugin author driver internals they never call.

Kit keeps them apart the same way the AST layer and the JSX renderer stay separate from the engine that drives them. You call `kubb/kit` to build things. The engine, reached through the `kubb` package and its CLI, runs them.
