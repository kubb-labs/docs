---
layout: doc
title: Integrations
description: Run Kubb as part of your bundler with kubb's build integrations. Supported targets include Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt and Astro.
outline: [2, 3]
---

# Integrations

`kubb`'s bundler entrypoints run code generation inside your build. You skip the separate `kubb generate` step. Pass the same config you write in `kubb.config.ts`, and Kubb runs it as part of your build instead. Each entrypoint is powered by [`unplugin-kubb`](https://www.npmjs.com/package/unplugin-kubb) under the hood, re-exported from `kubb` so you only install one package.

> [!NOTE]
> `hooks.done` runs formatters and linters after generation. It works with the [CLI](/docs/5.x/reference/commands/) only, not with unplugin. Use `kubb generate` when you need a post-generation callback.

> [!IMPORTANT]
> Vite-based bundlers ([Vite](./vite), [Nuxt](./nuxt), [Astro](./astro)) generate during a build only. They skip generation on dev server startup. Run [`kubb generate`](/docs/5.x/reference/commands/) before you start the dev server.

## Installation

Install `kubb` as a dev dependency.

::: code-group

```shell [bun]
bun add -d kubb@beta
```

```shell [pnpm]
pnpm add -D kubb@beta
```

```shell [npm]
npm install --save-dev kubb@beta
```

```shell [yarn]
yarn add -D kubb@beta
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
