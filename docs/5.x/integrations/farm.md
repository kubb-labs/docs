---
layout: doc
title: Farm Integration
description: Run Kubb as part of your Farm build with unplugin-kubb/farm.
outline: [2, 3]
---

# Farm

`unplugin-kubb/farm` runs Kubb as a [Farm](https://www.farmfe.org/) plugin. Farm is a Rust-based web build tool with a Vite-compatible plugin API.

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

```typescript [farm.config.ts]
import { defineConfig as defineFarmConfig } from '@farmfe/core'
import kubb from 'unplugin-kubb/farm'
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default defineFarmConfig({
  plugins: [kubb({ config })],
})
```
