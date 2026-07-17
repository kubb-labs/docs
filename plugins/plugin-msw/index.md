---
layout: doc
title: Kubb MSW Plugin
description: Generates MSW request handlers from your OpenAPI spec so you can
  mock the API in tests and during local development.
outline: deep
recipes:
  - id: handlers-you-fill-from-tests
    title: Handlers you fill from tests
  - id: auto-generated-mock-data
    title: Auto-generated mock data
  - id: register-handlers-with-a-server
    title: Register handlers with a server
kind: plugin
id: plugin-msw
name: MSW
category: mocks
type: official
npmPackage: "@kubb/plugin-msw"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-msw
featured: false
icon:
  light: https://kubb.dev/feature/msw.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - msw
  - mock-service-worker
  - api-mocking
  - mocks
  - testing
  - codegen
  - openapi
dependencies:
  - plugin-ts
  - plugin-faker
resources:
  documentation: https://kubb.dev/plugins/plugin-msw
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-msw/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/msw
---

# @kubb/plugin-msw

`@kubb/plugin-msw` turns your OpenAPI spec into [MSW](https://mswjs.io/) request handlers. Drop them into a test setup or a service worker to mock the API. Each handler matches the spec's path, method, status, and response body.

By default a handler returns an empty typed payload you fill in from tests. Set `parser: 'faker'` to return generated data from `@kubb/plugin-faker` instead.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-msw@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-msw@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-msw@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-msw@beta
```

:::

## Dependencies

This plugin always depends on [`@kubb/plugin-ts`](/plugins/plugin-ts/), so keep `pluginTs()` in the plugins array.

It depends on [`@kubb/plugin-faker`](/plugins/plugin-faker/) only when you set `parser: 'faker'`. With the default `parser: 'data'`, Faker is not needed.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({
      output: { path: './mocks', mode: 'directory' },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Service`,
      },
      handlers: true,
    }),
  ],
})
```

:::

## See also

- [MSW](https://mswjs.io/)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [@kubb/plugin-faker](/plugins/plugin-faker/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-msw/CHANGELOG.md)
