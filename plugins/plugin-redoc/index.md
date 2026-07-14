---
layout: doc
title: Kubb Redoc Plugin
description: Generates a single-file HTML page from your OpenAPI spec with Redoc,
  rebuilt on every Kubb run so the docs match the spec your code comes from.
outline: deep
kind: plugin
id: plugin-redoc
name: Redoc
category: documentation
type: official
npmPackage: "@kubb/plugin-redoc"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-redoc
featured: false
icon:
  light: https://kubb.dev/feature/openapi.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - redoc
  - api-docs
  - documentation
  - interactive-docs
  - codegen
  - openapi
dependencies: []
example: https://codesandbox.io/embed/github/kubb-labs/plugins/tree/main/examples/simple-single?module=/kubb.config.ts
resources:
  documentation: https://kubb.dev/plugins/plugin-redoc
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/simple-single
---

# @kubb/plugin-redoc

`@kubb/plugin-redoc` turns your OpenAPI spec into a static HTML documentation page with [Redoc](https://redocly.com/). The output is a single file with the spec embedded inline, so you can drop it on any static host without a build step. The page loads the Redoc bundle and fonts from a CDN when viewed, so rendering needs network access.

Kubb rebuilds the file on every run. Your docs stay in step with the spec your code was generated from.

This plugin reads the OpenAPI adapter. Kubb uses `adapterOas()` by default, so it works out of the box. You set `adapter` yourself only if you replaced that default with another adapter.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-redoc@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-redoc@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-redoc@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-redoc@beta
```

:::

## Dependencies

`@kubb/plugin-redoc` has no plugin dependencies. It reads the OpenAPI spec through `@kubb/adapter-oas` and needs no other Kubb plugin, so add it on its own whenever you want generated documentation.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginRedoc } from '@kubb/plugin-redoc'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  adapter: adapterOas(),
  plugins: [
    pluginRedoc({
      output: { path: 'docs.html' },
    }),
  ],
})
```

:::

## See also

- [Redoc](https://redocly.com/redoc)
- [adapterOas](/adapters/adapter-oas/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md)
