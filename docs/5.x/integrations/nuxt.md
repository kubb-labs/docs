---
layout: doc
title: Nuxt Integration
description: Run Kubb as part of your Nuxt application with the unplugin-kubb/nuxt module.
outline: [2, 3]
---

# Nuxt

`unplugin-kubb/nuxt` runs Kubb as a [Nuxt](https://nuxt.com/) module. It works with Nuxt 3 and Nuxt 4 and registers Kubb as both a Vite and webpack plugin depending on your Nuxt renderer.

## Install

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

Pass your Kubb config as the second element in the module tuple. `defineNuxtConfig` is auto-imported by Nuxt and does not need an explicit import.

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
> Because the Nuxt module delegates to the Vite plugin under the hood, generation only runs during `nuxt build`. It does not run during `nuxt dev`. Run [`kubb generate`](/docs/5.x/api/commands/) before starting the dev server.
