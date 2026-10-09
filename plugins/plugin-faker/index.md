---
layout: doc
title: Kubb Faker Plugin
description: Generates a Faker.js mock-data factory for every schema in your
  OpenAPI spec. Use the factories in tests, Storybook, and local development
  without a running backend.
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

Generate typed mock-data factories from OpenAPI schemas.

- Override generated values with partial data.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-faker
```

```shell [pnpm]
pnpm add -D @kubb/plugin-faker
```

```shell [npm]
npm install --save-dev @kubb/plugin-faker
```

```shell [yarn]
yarn add -D @kubb/plugin-faker
```

::

## Dependencies

- Add [`pluginTs`](/plugins/plugin-ts/) for factory return types.
- Generated factories require `@faker-js/faker` v9 or higher.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFaker({ seed: [100] }),
  ],
})
```

Set [`typeMode`](/plugins/plugin-faker/reference/options#typemode) to choose between inferred and declared model types for the factories.

## See also

- [Faker.js](https://fakerjs.dev/)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [@kubb/plugin-msw](/plugins/plugin-msw/)
