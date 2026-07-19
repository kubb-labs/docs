---
layout: doc
title: Run Kubb with Rolldown
description: Run Kubb as part of your Rolldown build with kubb/rolldown.
outline: [2, 3]
---

# Run Kubb with Rolldown

`kubb/rolldown` runs Kubb as a [Rolldown](https://rolldown.rs/) plugin. Rolldown is a Rust-based, Rollup-compatible bundler. Pass your Kubb config to the `config` option.

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

Add the plugin to your `rolldown.config.ts`:

```typescript [rolldown.config.ts]
import kubb from 'kubb/rolldown'
import { defineConfig } from 'rolldown'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default defineConfig({
  input: 'src/index.ts',
  plugins: [kubb({ config })],
})
```
