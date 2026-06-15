---
layout: doc
title: webpack Integration
description: Run Kubb as part of your webpack build with unplugin-kubb/webpack.
outline: [2, 3]
---

# webpack

`unplugin-kubb/webpack` runs Kubb during [webpack](https://webpack.js.org/) compilation. It works with both webpack 4 and webpack 5.

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

```javascript [webpack.config.js]
const kubb = require('unplugin-kubb/webpack')
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
