---
layout: doc
title: Astro Integration
description: Run Kubb as part of your Astro project with the unplugin-kubb/astro integration.
outline: [2, 3]
---

# Astro

`unplugin-kubb/astro` runs Kubb as an [Astro](https://astro.build/) integration. It hooks into Astro's Vite layer and generates during a build. Pass your Kubb config to the `config` option.

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
> The Astro integration uses Vite under the hood with `apply: 'build'`. Generation runs during `astro build` only. Run [`kubb generate`](/docs/5.x/api/commands/) before you start the dev server.
