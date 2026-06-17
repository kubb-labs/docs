---
layout: doc
title: Rollup Integration
description: Run Kubb as part of your Rollup build with unplugin-kubb/rollup.
outline: [2, 3]
---

# Rollup

`unplugin-kubb/rollup` runs Kubb as a [Rollup](https://rollupjs.org/) plugin. Generated files are written to disk in the `buildStart` hook, before the rest of the bundle runs.

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

```typescript twoslash [rollup.config.ts]
import kubb from 'unplugin-kubb/rollup'
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

export default {
  input: 'src/index.ts',
  plugins: [kubb({ config })],
}
```
