---
layout: doc
title: Integrations
description: Run Kubb as part of your bundler with unplugin-kubb. Supported targets include Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt and Astro.
outline: [2, 3]
---

# Integrations

`unplugin-kubb` runs code generation inside your build. You skip the separate `kubb generate` step. Pass it the same config you write in `kubb.config.ts`.

> [!NOTE]
> `hooks.done` runs formatters and linters after generation. It works with the [CLI](/docs/5.x/reference/commands/) only, not with unplugin. Use `kubb generate` when you need a post-generation callback.

> [!IMPORTANT]
> Vite-based bundlers ([Vite](./vite), [Nuxt](./nuxt), [Astro](./astro)) generate during a build only. They skip generation on dev server startup. Run [`kubb generate`](/docs/5.x/reference/commands/) before you start the dev server.

## Installation

Install the plugin as a dev dependency.

::: code-group

```shell [bun]
bun add -d unplugin-kubb@beta
```

```shell [pnpm]
pnpm add -D unplugin-kubb@beta
```

```shell [npm]
npm install --save-dev unplugin-kubb@beta
```

```shell [yarn]
yarn add -D unplugin-kubb@beta
```

:::

## Pick your bundler

Each bundler has its own entrypoint.

| Bundler                               | Entrypoint               | Docs                   |
| ------------------------------------- | ------------------------ | ---------------------- |
| [Vite](https://vitejs.dev/)           | `unplugin-kubb/vite`     | [Vite](./vite)         |
| [Rollup](https://rollupjs.org/)       | `unplugin-kubb/rollup`   | [Rollup](./rollup)     |
| [Rolldown](https://rolldown.rs/)      | `unplugin-kubb/rolldown` | [Rolldown](./rolldown) |
| [webpack](https://webpack.js.org/)    | `unplugin-kubb/webpack`  | [webpack](./webpack)   |
| [Rspack](https://rspack.dev/)         | `unplugin-kubb/rspack`   | [Rspack](./rspack)     |
| [esbuild](https://esbuild.github.io/) | `unplugin-kubb/esbuild`  | [esbuild](./esbuild)   |
| [Farm](https://www.farmfe.org/)       | `unplugin-kubb/farm`     | [Farm](./farm)         |
| [Nuxt](https://nuxt.com/)             | `unplugin-kubb/nuxt`     | [Nuxt](./nuxt)         |
| [Astro](https://astro.build/)         | `unplugin-kubb/astro`    | [Astro](./astro)       |

## Options

Pass your Kubb config to the `config` option. It takes a [`UserConfig`](/docs/5.x/reference/configuration) object with the same shape as `kubb.config.ts`.

```typescript [vite.config.ts]
import kubb from 'unplugin-kubb/vite'
import { defineConfig as defineViteConfig } from 'vite'
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default defineViteConfig({
  plugins: [kubb({ config })],
})
```
