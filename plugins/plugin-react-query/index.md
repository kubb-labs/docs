---
layout: doc
title: Kubb React Query Plugin
description: Generates typed TanStack Query hooks for React from your OpenAPI
  spec, so reads and writes call your API through useQuery, useMutation, and
  useInfiniteQuery without hand-written boilerplate.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
kind: plugin
id: plugin-react-query
name: React Query
category: framework
type: official
npmPackage: "@kubb/plugin-react-query"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-react-query
featured: true
icon:
  light: https://kubb.dev/feature/tanstack.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - react-query
  - tanstack-query
  - react
  - hooks
  - data-fetching
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-react-query
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/react-query
---

# @kubb/plugin-react-query

`@kubb/plugin-react-query` generates TanStack Query option factories and cache keys from OpenAPI operations. Set `hooks: true` to also generate React hooks.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-react-query
```

```shell [pnpm]
pnpm add -D @kubb/plugin-react-query
```

```shell [npm]
npm install --save-dev @kubb/plugin-react-query
```

```shell [yarn]
yarn add -D @kubb/plugin-react-query
```

::

## Dependencies

Add [`pluginTs`](/plugins/plugin-ts/) and an [Axios](/plugins/plugin-axios/) or [Fetch](/plugins/plugin-fetch/) client plugin. Generated output requires `@tanstack/react-query` v5 or higher. Configure validation on the client plugin.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginReactQuery({ hooks: true }),
  ],
})
```

## Documentation

- [Options](./reference/options)
- [Call operations](./guide/calling-operations)

## See also

- [TanStack Query](https://tanstack.com/query)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md)
