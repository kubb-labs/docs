---
layout: doc
title: Run Kubb with Rolldown
description: Run Kubb as part of your Rolldown build with unplugin-kubb/rolldown.
outline: [2, 3]
---

# Run Kubb with Rolldown

`unplugin-kubb/rolldown` runs Kubb as a [Rolldown](https://rolldown.rs/) plugin. Rolldown is a Rust-based, Rollup-compatible bundler. Pass your Kubb config to the `config` option.

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

Add the plugin to your `rolldown.config.ts` and pass it your Kubb config.

```typescript [rolldown.config.ts]
import kubb from 'unplugin-kubb/rolldown'
import { defineConfig as defineRolldownConfig } from 'rolldown'
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default defineRolldownConfig({
  input: 'src/index.ts',
  plugins: [kubb({ config })],
})
```
