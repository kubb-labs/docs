---
layout: doc
title: Kubb Vue Query Plugin
description: Generates TanStack Query composables for Vue from your OpenAPI
  spec, so every read and write is a typed useQuery, useInfiniteQuery, or
  useMutation.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
kind: plugin
id: plugin-vue-query
name: Vue Query
category: framework
type: official
npmPackage: "@kubb/plugin-vue-query"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-vue-query
featured: false
icon:
  light: https://kubb.dev/feature/tanstack.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - vue-query
  - tanstack-query
  - vue
  - composables
  - data-fetching
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-vue-query
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-vue-query/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/vue-query
---

# @kubb/plugin-vue-query

`@kubb/plugin-vue-query` generates TanStack Query option factories and cache keys from OpenAPI operations. Set `hooks: true` to also generate Vue composables with reactive parameters.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-vue-query
```

```shell [pnpm]
pnpm add -D @kubb/plugin-vue-query
```

```shell [npm]
npm install --save-dev @kubb/plugin-vue-query
```

```shell [yarn]
yarn add -D @kubb/plugin-vue-query
```

::

## Dependencies

Add [`pluginTs`](/plugins/plugin-ts/) and an [Axios](/plugins/plugin-axios/) or [Fetch](/plugins/plugin-fetch/) client plugin. Generated output requires `@tanstack/vue-query` v5 or higher. Configure validation on the client plugin.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginVueQuery({ hooks: true }),
  ],
})
```

## Documentation

::card-group

:::card{title="Options" to="/plugins/plugin-vue-query/reference/options"}
:::

:::card{title="Call operations" to="/plugins/plugin-vue-query/guide/calling-operations"}
:::

::

## See also

- [TanStack Query for Vue](https://tanstack.com/query/latest/docs/framework/vue/overview)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-vue-query/CHANGELOG.md)
