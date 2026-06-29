---
layout: doc
title: Run Kubb with Nuxt
description: Run Kubb as part of your Nuxt application with the unplugin-kubb/nuxt module.
outline: [2, 3]
---

# Run Kubb with Nuxt

`unplugin-kubb/nuxt` runs Kubb as a [Nuxt](https://nuxt.com/) module. It works with Nuxt 3 and Nuxt 4. The module registers Kubb as both a Vite plugin and a webpack plugin, so Nuxt picks the right one for its active builder.

## Install

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

## Configure

Pass your Kubb config as the second element of the module tuple. Nuxt auto-imports `defineNuxtConfig`, so you do not import it.

```typescript [nuxt.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default defineNuxtConfig({
  modules: [['unplugin-kubb/nuxt', { config }]],
})
```

> [!NOTE]
> With the default Vite builder, generation runs during `nuxt build` only, not during `nuxt dev`. Run [`kubb generate`](/docs/5.x/api/commands/) before you start the dev server.
