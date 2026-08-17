---
layout: doc
title: Run Kubb with webpack
description: Run Kubb as part of your webpack build with kubb/webpack.
outline: [2, 3]
---

# Run Kubb with webpack

`kubb/webpack` runs Kubb during [webpack](https://webpack.js.org/) compilation. It requires webpack 5. Pass your Kubb config to the `config` option.

## Install

Install `kubb` as a dev dependency.

::: code-group

```shell [bun]
bun add -d kubb@5.0.0
```

```shell [pnpm]
pnpm add -D kubb@5.0.0
```

```shell [npm]
npm install --save-dev kubb@5.0.0
```

```shell [yarn]
yarn add -D kubb@5.0.0
```

:::

## Configure

Add the plugin to your `webpack.config.js`:

```javascript [webpack.config.js]
const kubb = require('kubb/webpack')
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
