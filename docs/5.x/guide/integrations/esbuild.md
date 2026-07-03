---
layout: doc
title: Run Kubb with esbuild
description: Run Kubb as part of your esbuild build with kubb/esbuild.
outline: [2, 3]
---

# Run Kubb with esbuild

`kubb/esbuild` runs Kubb as an [esbuild](https://esbuild.github.io/) plugin. Add it to the `plugins` array in your build script. Pass your Kubb config to the `config` option.

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

Add the plugin to the `plugins` array in your build script and pass it your Kubb config.

```typescript [build.ts]
import { build } from 'esbuild'
import kubb from 'kubb/esbuild'
import { pluginTs } from '@kubb/plugin-ts'

const config = {
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

await build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/bundle.js',
  plugins: [kubb({ config })],
})
```
