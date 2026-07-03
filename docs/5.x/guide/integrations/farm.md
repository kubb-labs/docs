---
layout: doc
title: Run Kubb with Farm
description: Run Kubb as part of your Farm build with unplugin-kubb/farm.
outline: [2, 3]
---

# Run Kubb with Farm

`unplugin-kubb/farm` runs Kubb as a [Farm](https://www.farmfe.org/) plugin. Farm is a Rust-based web build tool with a Vite-compatible plugin API. Pass your Kubb config to the `config` option.

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

Add the plugin to your `farm.config.ts` and pass it your Kubb config.

```typescript [farm.config.ts]
import { defineConfig as defineFarmConfig } from '@farmfe/core'
import kubb from 'unplugin-kubb/farm'
import { defineConfig } from 'kubb/config'
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
