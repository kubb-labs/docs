---
layout: doc
title: Run Kubb with Farm
description: Run Kubb as part of your Farm build with kubb/farm.
outline: [2, 3]
---

# Run Kubb with Farm

`kubb/farm` runs Kubb as a [Farm](https://www.farmfe.org/) plugin. Farm is a Rust-based web build tool with a Vite-compatible plugin API. Pass your Kubb config to the `config` option.

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

Add the plugin to your `farm.config.ts` and pass it your Kubb config.

```typescript [farm.config.ts]
import { defineConfig } from '@farmfe/core'
import kubb from 'kubb/farm'
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
