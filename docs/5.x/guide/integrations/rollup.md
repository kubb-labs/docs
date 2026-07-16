---
layout: doc
title: Run Kubb with Rollup
description: Run Kubb as part of your Rollup build with kubb/rollup.
outline: [2, 3]
---

# Run Kubb with Rollup

`kubb/rollup` runs Kubb as a [Rollup](https://rollupjs.org/) plugin. It writes the generated files in the `buildStart` hook, before the rest of the bundle runs. Pass your Kubb config to the `config` option.

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

Add the plugin to your `rollup.config.ts` and pass it your Kubb config.

```typescript twoslash [rollup.config.ts]
import kubb from 'kubb/rollup'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

export default {
  input: 'src/index.ts',
  plugins: [kubb({ config })],
}
```
