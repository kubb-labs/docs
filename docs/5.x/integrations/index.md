---
layout: doc
title: Integrations
description: Run Kubb as part of your bundler with unplugin-kubb. Supported targets include Vite, Rollup, Rolldown, webpack, Rspack, esbuild, Farm, Nuxt and Astro.
outline: [2, 3]
---

# Integrations

`unplugin-kubb` runs code generation as part of your build pipeline instead of as a separate `kubb generate` step. Pass it the same config you would write in `kubb.config.ts`.

> [!NOTE]
> `hooks.done` (for running formatters or linters after generation) only works with the [CLI](/docs/5.x/api/commands/), not with unplugin. Use `kubb generate` if you need post-generation callbacks.

> [!IMPORTANT]
> For Vite-based bundlers ([Vite](./vite), [Nuxt](./nuxt), [Astro](./astro)), generation only runs during builds. It does not run during dev server startup. Run [`kubb generate`](/docs/5.x/api/commands/) before starting the dev server.

## Installation

::: code-group

```shell [bun]
bun add -d unplugin-kubb
```

```shell [pnpm]
pnpm add -D unplugin-kubb
```

```shell [npm]
npm install --save-dev unplugin-kubb
```

```shell [yarn]
yarn add -D unplugin-kubb
```

:::

## Pick your bundler

Each bundler has a dedicated entrypoint. Pick the one that matches your tooling:

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

Pass your Kubb config to the `config` option. The value is a [`UserConfig`](/docs/5.x/reference/configuration) object with the same shape as `kubb.config.ts`:

```typescript twoslash [vite.config.ts]
import kubb from 'unplugin-kubb/vite'
import { defineConfig as defineViteConfig } from 'vite'
import { defineConfig } from 'kubb'
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
