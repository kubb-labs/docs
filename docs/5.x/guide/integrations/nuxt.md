---
layout: doc
title: Run Kubb with Nuxt
description: Run Kubb as part of your Nuxt application with the kubb/nuxt module.
outline: [2, 3]
---

# Run Kubb with Nuxt

`kubb/nuxt` runs Kubb as a [Nuxt](https://nuxt.com/) module. It works with Nuxt 3 and Nuxt 4. The module registers Kubb as both a Vite plugin and a webpack plugin, so Nuxt picks the right one for its active builder.

## Install

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

## Configure

Pass your Kubb config as the second element of the module tuple. Nuxt auto-imports `defineNuxtConfig`, so you do not import it.

```typescript [nuxt.config.ts]
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default defineNuxtConfig({
  modules: [['kubb/nuxt', { config }]],
})
```

> [!NOTE]
> With the default Vite builder, generation runs during `nuxt build` only, not during `nuxt dev`. Run [`kubb generate`](/docs/5.x/reference/commands/) before you start the dev server.
