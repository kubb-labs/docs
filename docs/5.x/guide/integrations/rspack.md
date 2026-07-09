---
layout: doc
title: Run Kubb with Rspack
description: Run Kubb as part of your Rspack build with kubb/rspack.
outline: [2, 3]
---

# Run Kubb with Rspack

`kubb/rspack` runs Kubb during [Rspack](https://rspack.dev/) compilation. Rspack is a Rust-based bundler with a webpack-compatible config. Pass your Kubb config to the `config` option.

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

Add the plugin to your `rspack.config.js` and pass it your Kubb config.

```javascript [rspack.config.js]
const kubb = require('kubb/rspack')
const { pluginTs } = require('@kubb/plugin-ts')

const config = {
  root: '.',
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

module.exports = {
  plugins: [kubb({ config })],
}
```
