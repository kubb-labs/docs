---
layout: doc
title: Kubb Faker Plugin
description: Generate Faker.js mock-data factories from OpenAPI for tests,
  Storybook, and seeded local data.
outline: deep
kind: plugin
id: plugin-faker
name: Faker
category: mocks
type: official
npmPackage: "@kubb/plugin-faker"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-faker
featured: false
icon:
  light: https://kubb.dev/feature/faker.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - faker
  - mock-data
  - mocks
  - fixtures
  - testing
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-faker
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-faker/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/faker
---

# @kubb/plugin-faker

`@kubb/plugin-faker` builds a mock-data factory for every schema in your OpenAPI spec with [Faker.js](https://fakerjs.dev/). Call `createPet()` to get a realistic `Pet` object. Use the factories in tests, Storybook stories, and local development without a backend.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-faker@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-faker@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-faker@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-faker@beta
```

:::

## Dependencies

This plugin depends on [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the types each factory returns. Keep `pluginTs()` in the plugins array. No other plugin is required.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginTs({
      output: { path: './types' },
    }),
    pluginFaker({
      output: { path: './mocks' },
      seed: [100],
    }),
  ],
})
```

:::

## See also

- [Faker.js](https://fakerjs.dev/)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [@kubb/plugin-msw](/plugins/plugin-msw/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-faker/CHANGELOG.md)
