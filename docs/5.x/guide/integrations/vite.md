---
layout: doc
title: Run Kubb with Vite
description: Run Kubb as part of your Vite build with unplugin-kubb/vite.
outline: [2, 3]
---

# Run Kubb with Vite

`unplugin-kubb/vite` runs Kubb as a [Vite](https://vitejs.dev/) plugin. Add it to `vite.config.ts`. Pass your Kubb config to the `config` option.

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

Add the plugin to your `vite.config.ts` and pass it your Kubb config.

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
