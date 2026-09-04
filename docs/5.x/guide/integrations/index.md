---
layout: doc
title: Integrations
description: Run Kubb from somewhere other than the CLI. Generate inside your bundler with Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt or Astro, or from the browser with Kubb Studio.
outline: [2, 3]
---

# Integrations

Kubb runs from the CLI, and it also runs from the places you already work. A bundler integration generates during your build, and [Kubb Studio](./studio) generates from a browser tab while Kubb runs on your machine.

## Bundlers

`kubb`'s bundler entrypoints run code generation inside your build. You skip the separate `kubb generate` step. Pass the same config you write in `kubb.config.ts`, and Kubb runs it as part of your build instead. Each entrypoint is powered by [`unplugin-kubb`](https://www.npmjs.com/package/unplugin-kubb) under the hood, re-exported from `kubb` so you only install one package.

> [!NOTE]
> `output.postGenerate` runs commands after generation. It works with the [CLI](/docs/5.x/reference/commands/) only, not with unplugin. Use `kubb generate` when you need a post-generation command.

> [!IMPORTANT]
> Vite-based bundlers ([Vite](./vite), [Nuxt](./nuxt), [Astro](./astro)) generate during a build only. They skip generation on dev server startup. Run [`kubb generate`](/docs/5.x/reference/commands/) before you start the dev server.

## Installation

Install `kubb` as a dev dependency.

::: code-group

```shell [bun]
bun add -d kubb
```

```shell [pnpm]
pnpm add -D kubb
```

```shell [npm]
npm install --save-dev kubb
```

```shell [yarn]
yarn add -D kubb
```

:::

## Pick your bundler

Each bundler has its own entrypoint.

| Bundler                               | Entrypoint       | Docs                   |
| ------------------------------------- | ---------------- | ----------------------- |
| [Vite](https://vitejs.dev/)           | `kubb/vite`     | [Vite](./vite)         |
| [Rollup](https://rollupjs.org/)       | `kubb/rollup`   | [Rollup](./rollup)     |
| [Rolldown](https://rolldown.rs/)      | `kubb/rolldown` | [Rolldown](./rolldown) |
| [webpack](https://webpack.js.org/)    | `kubb/webpack`  | [webpack](./webpack)   |
| [Rspack](https://rspack.dev/)         | `kubb/rspack`   | [Rspack](./rspack)     |
| [esbuild](https://esbuild.github.io/) | `kubb/esbuild`  | [esbuild](./esbuild)   |
| [Farm](https://www.farmfe.org/)       | `kubb/farm`     | [Farm](./farm)         |
| [Nuxt](https://nuxt.com/)             | `kubb/nuxt`     | [Nuxt](./nuxt)         |
| [Astro](https://astro.build/)         | `kubb/astro`    | [Astro](./astro)       |

## Options

Pass your Kubb config to the `config` option. It takes a [`UserConfig`](/docs/5.x/reference/configuration) object with the same shape as `kubb.config.ts`.

```typescript [vite.config.ts]
import kubb from 'kubb/vite'
import { defineConfig as defineViteConfig } from 'vite'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default defineViteConfig({
  plugins: [kubb({ config })],
})
```

## Kubb Studio

[Kubb Studio](./studio) is the other way in, and it works differently from the entrypoints above. Rather than generating during a build, you open a session with `kubb studio` and drive generation from a browser tab. Kubb still runs on your machine against the files on disk, so your spec is never uploaded.

Reach for it when you want to change plugin options and see the result straight away, and for a bundler entrypoint when generation should happen as part of your build.
