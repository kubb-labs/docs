---
layout: doc
title: Kubb Barrel Plugin
description: Generates an index.ts barrel for every plugin output and one root
  barrel, so you import all generated code from a single entry point. Ships with
  Kubb, but only generates barrels once output.barrel is configured.
outline: deep
kind: plugin
id: plugin-barrel
name: Barrel
category: output
type: official
npmPackage: "@kubb/plugin-barrel"
repo: https://github.com/kubb-labs/kubb
docsPath: /plugins/plugin-barrel
featured: true
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - barrel
  - index
  - exports
  - output
resources:
  documentation: https://kubb.dev/plugins/plugin-barrel
  repository: https://github.com/kubb-labs/kubb
  issues: https://github.com/kubb-labs/kubb/issues
  changelog: https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md
---

# @kubb/plugin-barrel

`@kubb/plugin-barrel` generates `index.ts` files for plugin outputs and a root entry point. Kubb registers it by default. Configure [`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel) to control exports.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-barrel
```

```shell [pnpm]
pnpm add -D @kubb/plugin-barrel
```

```shell [npm]
npm install --save-dev @kubb/plugin-barrel
```

```shell [yarn]
yarn add -D @kubb/plugin-barrel
```

::

## Dependencies

No plugin dependencies. The plugin ships with Kubb and runs by default. Do not add it to `plugins`.

## Example

Set `output.barrel` on the root configuration to enable a root barrel and the default inherited by plugins without their own barrel setting.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', barrel: { type: 'named' } },
  plugins: [pluginTs()],
})
```

Use `'all'` for wildcard exports. Set a plugin's `output.barrel` to `false` to exclude its files, or enable `nested` to reference subdirectory barrels. See [Options](/plugins/plugin-barrel/reference/options).

## Documentation

::card-group

:::card{title="Options" to="/plugins/plugin-barrel/reference/options"}
:::

::

## See also

- [Changelog](https://github.com/kubb-labs/kubb/blob/main/packages/plugin-barrel/CHANGELOG.md)
