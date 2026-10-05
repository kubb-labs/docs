---
layout: doc
title: Kubb SWR Plugin
description: Generates typed SWR hooks from your OpenAPI spec, so data fetching
  stays in sync with the API.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
kind: plugin
id: plugin-swr
name: SWR
category: framework
type: official
npmPackage: "@kubb/plugin-swr"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-swr
featured: true
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - swr
  - react
  - hooks
  - data-fetching
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-swr
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/swr
---

# @kubb/plugin-swr

`@kubb/plugin-swr` generates typed [SWR](https://swr.vercel.app/) hooks from OpenAPI operations. Each hook calls a generated Axios or Fetch client.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-swr
```

```shell [pnpm]
pnpm add -D @kubb/plugin-swr
```

```shell [npm]
npm install --save-dev @kubb/plugin-swr
```

```shell [yarn]
yarn add -D @kubb/plugin-swr
```

::

## Dependencies

Add [`pluginTs`](/plugins/plugin-ts/) and an [Axios](/plugins/plugin-axios/) or [Fetch](/plugins/plugin-fetch/) client plugin. Generated hooks require SWR v2 or higher. Configure validation on the client plugin.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginSwr(),
  ],
})
```

## Documentation

- [Options](./reference/options)
- [Call operations](./guide/calling-operations)

## See also

- [SWR](https://swr.vercel.app)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md)
