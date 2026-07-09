---
layout: doc
title: Kubb Vue Query Plugin
description: Generates TanStack Query composables for Vue from your OpenAPI spec, so
  every read and write is a typed useQuery, useInfiniteQuery, or useMutation.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
  - id: macros
    title: Write macros
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

`@kubb/plugin-vue-query` turns each OpenAPI operation into a [TanStack Query](https://tanstack.com/query) composable for Vue. Read operations become `useFoo`, with an optional `useFooInfinite` variant. Write operations become `useFoo` mutations. Every composable is typed: query keys, input variables, response data, and error shape all come from the spec.

The composables call an HTTP client, so a client plugin must be registered. Add `@kubb/plugin-ts` for the types and either `@kubb/plugin-axios` or `@kubb/plugin-fetch` for the client. Generation errors out when no client plugin is present.

Each composable takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-vue-query@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-vue-query@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-vue-query@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-vue-query@beta
```

:::

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the types.
- A client plugin, [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), for the HTTP layer. The composables call its functions, so generation errors out when no client plugin is registered.

For runtime validation, set `validator` on the client plugin. The generated operations carry the validation, so the composables get it for free.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginAxios(),
    pluginVueQuery({
      output: { path: './hooks' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Hooks`,
      },
      client: 'axios',
      mutation: { methods: ['POST', 'PUT', 'DELETE'] },
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
      },
      query: {
        methods: ['GET'],
        importPath: '@tanstack/vue-query',
      },
    }),
  ],
})
```

:::

## See also

- [TanStack Query for Vue](https://tanstack.com/query/latest/docs/framework/vue/overview)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-vue-query/CHANGELOG.md)
