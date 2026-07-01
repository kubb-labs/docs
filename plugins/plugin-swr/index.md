---
layout: doc
title: Kubb SWR Plugin
description: Generates typed SWR hooks from your OpenAPI spec, so data fetching stays in sync with the API.
outline: deep
guides:
  - id: calling-operations
    title: Call operations
  - id: macros
    title: Write macros
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
  - validator
dependencies:
  - plugin-ts
  - plugin-axios
resources:
  documentation: https://kubb.dev/plugins/plugin-swr
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/swr
---

# @kubb/plugin-swr

`@kubb/plugin-swr` turns each OpenAPI operation into an [SWR](https://swr.vercel.app) hook. Read operations become `useSWR` hooks. Write operations become `useSWRMutation` hooks. Every hook is typed: keys, input variables, response data, and error shape all come from the spec.

The hooks call an HTTP client, so a client plugin must be registered. Add `@kubb/plugin-ts` for the types and either `@kubb/plugin-axios` or `@kubb/plugin-fetch` for the client. Generation errors out when no client plugin is present.

Each hook takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-swr@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-swr@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-swr@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-swr@beta
```

:::

## Dependencies

This plugin needs these plugins in your config:

- [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the types.
- A client plugin, [`@kubb/plugin-axios`](/plugins/plugin-axios/) or [`@kubb/plugin-fetch`](/plugins/plugin-fetch/), for the HTTP layer. The hooks call its functions, so generation errors out when no client plugin is registered.

Set `validator` to `'zod'` and the plugin also depends on [`@kubb/plugin-zod`](/plugins/plugin-zod/), which then has to be in the plugins list.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginSwr({
      output: { path: './hooks' },
      group: { type: 'tag', name: ({ group }) => `${group}Hooks` },
      client: 'fetch',
      query: { methods: ['get'], importPath: 'swr' },
      mutation: { methods: ['post', 'put', 'patch', 'delete'] },
    }),
  ],
})
```

:::

## See Also

- [SWR](https://swr.vercel.app)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-swr/CHANGELOG.md)
