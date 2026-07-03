---
layout: doc
title: Run Kubb with webpack
description: Run Kubb as part of your webpack build with unplugin-kubb/webpack.
outline: [2, 3]
---

# Run Kubb with webpack

`unplugin-kubb/webpack` runs Kubb during [webpack](https://webpack.js.org/) compilation. It requires webpack 5. Pass your Kubb config to the `config` option.

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

Add the plugin to your `webpack.config.js` and pass it your Kubb config.

```javascript [webpack.config.js]
const kubb = require('unplugin-kubb/webpack')
const { pluginTs } = require('@kubb/plugin-ts')

const config = {
  root: '.',
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'models' } })],
}

module.exports = {
  plugins: [kubb({ config })],
}
```
