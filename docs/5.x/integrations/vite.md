---
layout: doc
title: Vite Integration
description: Run Kubb as part of your Vite build with unplugin-kubb/vite.
outline: [2, 3]
---

# Vite

`unplugin-kubb/vite` runs Kubb as a [Vite](https://vitejs.dev/) plugin. Add it to `vite.config.ts` and pass your Kubb config to the `config` option.

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
