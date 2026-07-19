---
layout: doc
title: Kubb React Query Plugin
description: Generates typed TanStack Query hooks for React from your OpenAPI spec, so
  reads and writes call your API through useQuery, useMutation, and useInfiniteQuery
  without hand-written boilerplate.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
recipes:
  - id: infinite-scroll-query
    title: Infinite scroll query
  - id: custom-query-keys
    title: Custom query keys
  - id: wrap-hooks-with-shared-options
    title: Wrap every hook with shared options
  - id: suspense-hooks
    title: Suspense hooks
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

`@kubb/plugin-react-query` turns each OpenAPI operation into a [TanStack Query](https://tanstack.com/query) hook for React. Read operations become `useFoo`, with `useFooSuspense` and `useFooInfinite` variants. Write operations become `useFoo` mutations. Every hook is typed: query keys, input variables, response data, and error shape all come from the spec.

The hooks call an HTTP client, so a client plugin must be registered: `@kubb/plugin-ts` for the types, plus either `@kubb/plugin-axios` or `@kubb/plugin-fetch` for the client.

Each hook takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-react-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-react-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-react-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-react-query@beta
```

:::

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the types.
- A client plugin, [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), for the HTTP layer. The hooks call its functions, so generation errors out when no client plugin is registered.

For runtime validation, set `validator` on the client plugin. The generated operations carry the validation, so the hooks get it for free.

## Example

::: code-group

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
    pluginReactQuery({
      output: { path: './hooks', mode: 'directory' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Hooks`,
      },
      client: 'fetch',
      mutation: { methods: ['POST', 'PUT', 'DELETE'] },
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
        previousParam: ['pagination', 'prev', 'cursor'],
      },
      query: {
        methods: ['GET'],
        importPath: '@tanstack/react-query',
      },
      suspense: {},
    }),
  ],
})
```

:::

## See also

- [TanStack Query](https://tanstack.com/query)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-react-query/CHANGELOG.md)
