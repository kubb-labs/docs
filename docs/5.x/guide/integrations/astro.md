---
layout: doc
title: Run Kubb with Astro
description: Run Kubb as part of your Astro project with the unplugin-kubb/astro integration.
outline: [2, 3]
---

# Run Kubb with Astro

`unplugin-kubb/astro` runs Kubb as an [Astro](https://astro.build/) integration. It hooks into Astro's Vite layer and generates during a build. Pass your Kubb config to the `config` option.

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

Add the integration to your `astro.config.mjs` and pass it your Kubb config.

```typescript [astro.config.mjs]
import { defineConfig as defineAstroConfig } from 'astro/config'
import kubb from 'unplugin-kubb/astro'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default defineAstroConfig({
  integrations: [kubb({ config })],
})
```

> [!NOTE]
> The Astro integration runs through Vite with `apply: 'build'`. Generation runs during `astro build` only. Run [`kubb generate`](/docs/5.x/reference/commands/) before you start the dev server.
