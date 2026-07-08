---
layout: doc
title: Renderers
description: createRenderer wraps a builder into a Renderer factory for generators that emit something other than plain FileNodes, alongside jsxRenderer, the React-free JSX renderer shipped in kubb/jsx.
outline: [2, 3]
---

# Renderers

A renderer turns the elements a generator returns into `FileNode`s. Kubb ships a JSX renderer through [`kubb/jsx`](/docs/5.x/reference/jsx). Reach for `createRenderer` only when you want a different templating format.

## `createRenderer`

`createRenderer` takes a builder function and returns a factory that produces a `Renderer`, the object a generator's `renderer` field points at. It follows the same builder-to-factory shape as `createStorage`: call the builder once, get back a reusable factory, call the factory to get an instance.

Reach for `createRenderer` when a generator needs to emit something other than plain `FileNode` arrays or [`kubb/jsx`](/docs/5.x/reference/jsx) elements, for example a renderer that walks a different templating format into `FileNode`s. `kubb/jsx`'s own `jsxRenderer` ships as a plain factory and does not depend on `createRenderer`, so most plugin authors only need `createRenderer` when they are building an alternative to JSX rendering.

### Related

- [Renderer concepts](/docs/5.x/guide/concepts/renderers)
- [`jsxRenderer`](#jsxrenderer-via-kubb-jsx), the shipped JSX renderer
- [Creating plugins](/docs/5.x/guide/going-further/creating-plugins)

## `jsxRenderer` (via `kubb/jsx`) {#jsxrenderer-via-kubb-jsx}

For JSX-based rendering, import `jsxRenderer` from [`kubb/jsx`](/docs/5.x/reference/jsx), backed by the internal `@kubb/renderer-jsx` package.

`jsxRenderer` is a React-free recursive renderer. It walks the JSX components into `FileNode`s without a React reconciliation pass. Components run as plain functions, so hooks and suspense are not available.

```typescript twoslash [renderer.ts]
import { jsxRenderer } from 'kubb/jsx'

const renderer = jsxRenderer()
```

Set the renderer on a generator through its `renderer` field (`renderer: jsxRenderer`) to enable JSX-based output for that generator. Leave it unset, or pass `renderer: null`, to opt out of rendering. See the [JSX API reference](/docs/5.x/reference/jsx) for `File`, `Function`, `Type`, `Const`, and the `jsx-runtime` / `jsx-dev-runtime` subpaths.
