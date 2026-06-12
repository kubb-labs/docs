---
layout: doc
title: Astro Integration
description: Run Kubb as part of your Astro project with the unplugin-kubb/astro integration.
outline: [2, 3]
---

# Astro

`unplugin-kubb/astro` runs Kubb as an [Astro](https://astro.build/) integration. It hooks into Astro's Vite layer and runs generation during builds.

## Install

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

## Configure

```typescript [astro.config.mjs]
import { defineConfig as defineAstroConfig } from 'astro/config'
import kubb from 'unplugin-kubb/astro'
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default defineAstroConfig({
  integrations: [kubb({ config })],
})
```

> [!NOTE]
> The Astro integration uses Vite under the hood with `apply: 'build'`, so generation runs during `astro build` only. Run [`kubb generate`](/docs/5.x/api/commands/) before starting the dev server.
