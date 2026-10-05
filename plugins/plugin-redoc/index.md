---
layout: doc
title: Kubb Redoc Plugin
description: Generates a single-file HTML page from your OpenAPI spec with
  Redoc, rebuilt on every Kubb run so the docs match the spec your code comes
  from.
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
resources:
  documentation: https://kubb.dev/plugins/plugin-redoc
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/simple-single
---

# @kubb/plugin-redoc

`@kubb/plugin-redoc` generates a single HTML documentation page with [Redoc](https://redocly.com/). The spec is embedded in the file. Publish it to a static host without a build step. Rendering requires network access for CDN scripts and fonts.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-redoc
```

```shell [pnpm]
pnpm add -D @kubb/plugin-redoc
```

```shell [npm]
npm install --save-dev @kubb/plugin-redoc
```

```shell [yarn]
yarn add -D @kubb/plugin-redoc
```

::

## Dependencies

No plugin dependencies. Kubb uses the OpenAPI adapter by default. The generated page loads Redoc from a CDN, so no Redoc runtime package is required.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginRedoc } from '@kubb/plugin-redoc'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginRedoc({ output: { path: 'docs.html' } }),
  ],
})
```

## Documentation

- [Options](./reference/options)

## See also

- [Redoc](https://redocly.com/redoc)
- [adapterOas](/adapters/adapter-oas/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-redoc/CHANGELOG.md)
