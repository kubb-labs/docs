---
layout: doc
title: Run Kubb with Vite
description: Run Kubb as part of your Vite build with kubb/vite.
outline: [2, 3]
---

# Run Kubb with Vite

`kubb/vite` runs Kubb as a [Vite](https://vitejs.dev/) plugin. Add it to `vite.config.ts`. Pass your Kubb config to the `config` option.

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

Add the plugin to your `vite.config.ts` and pass it your Kubb config.

```typescript [vite.config.ts]
import kubb from 'kubb/vite'
import { defineConfig } from 'vite'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default defineConfig({
  plugins: [kubb({ config })],
})
```
