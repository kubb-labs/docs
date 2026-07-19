---
layout: doc
title: Renderers - How Generators Emit Files
description: A renderer turns what a generator returns into FileNodes. Kubb ships a JSX renderer, and you build your own only when you emit through a different templating format.
outline: deep
---

# Renderers

A renderer is the step between what a generator returns and the `FileNode`s the engine writes. A generator produces output two ways: it builds `FileNode`s directly with the `ast.factory` node builders, or it returns elements and lets a renderer walk them into `FileNode`s. The renderer is the second path.

<FlowDiagram preset="renderer" />

## Why rendering is a separate step

Building files by hand with `ast.factory` is precise, but it gets verbose once a file has imports, several declarations, and JSDoc. JSX reads better for that, letting a generator describe output as components and nesting instead of a flat list of `create*` calls. Keeping the renderer separate means the generator does not care which style produced the file, since the engine gets `FileNode`s either way.

Kubb ships [`kubb/jsx`](/docs/5.x/reference/jsx) for the JSX path. Its `jsxRenderer` is React-free: components run as plain functions, so hooks and suspense are not available. A generator turns it on by setting its `renderer` field.

## When you write your own

Most plugins never need a custom renderer. Reach for [`createRenderer`](/docs/5.x/reference/kit/renderers) only when a generator emits through some other templating format and needs it walked into `FileNode`s. If you are building files directly or through JSX, the shipped tools already cover you.
