---
layout: doc
title: Kubb MSW Plugin
description: Generates MSW request handlers from your OpenAPI spec so you can
  mock the API in tests and during local development.
outline: deep
guides:
  - id: mock-api
    title: Mock API responses
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

Generate typed [MSW](https://mswjs.io/) handlers from OpenAPI.

- Supply response data in tests.
- Generate mock responses with Faker.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-msw
```

```shell [pnpm]
pnpm add -D @kubb/plugin-msw
```

```shell [npm]
npm install --save-dev @kubb/plugin-msw
```

```shell [yarn]
yarn add -D @kubb/plugin-msw
```

::

## Dependencies

- Add [`pluginTs`](/plugins/plugin-ts/).
- Add [`pluginFaker`](/plugins/plugin-faker/) for `parser: 'faker'`. The default `'data'` parser does not need it.
- Generated handlers require MSW v2 or higher.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginMsw({ output: { path: 'handlers', mode: 'directory' }, handlers: true }),
  ],
})
```

## See also

- [MSW](https://mswjs.io/)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [@kubb/plugin-faker](/plugins/plugin-faker/)
