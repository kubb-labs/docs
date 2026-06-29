---
layout: doc
title: Rspack Integration
description: Run Kubb as part of your Rspack build with unplugin-kubb/rspack.
outline: [2, 3]
---

# Rspack

`unplugin-kubb/rspack` runs Kubb during [Rspack](https://rspack.dev/) compilation. Rspack is a Rust-based bundler with a webpack-compatible config. Pass your Kubb config to the `config` option.

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

Add the plugin to your `rspack.config.js` and pass it your Kubb config.

```javascript [rspack.config.js]
const kubb = require('unplugin-kubb/rspack')
const { defineConfig } = require('kubb')
const { pluginTs } = require('@kubb/plugin-ts')

const config = defineConfig({
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
})

module.exports = {
  plugins: [kubb({ config })],
}
```
