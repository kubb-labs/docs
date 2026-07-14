---
layout: doc
title: Kubb Cypress Plugin
description: Generates a typed cy.request() wrapper per OpenAPI operation so your
  Cypress tests call the API through generated helpers and catch broken calls at compile time.
outline: deep
recipes:
  - id: typed-request-helpers-against-staging
    title: Typed request helpers against staging
kind: plugin
id: plugin-cypress
name: Cypress
category: testing
type: official
npmPackage: "@kubb/plugin-cypress"
repo: https://github.com/kubb-labs/plugins
docsPath: /plugins/plugin-cypress
featured: false
icon:
  light: https://kubb.dev/feature/cypress.svg
maintainers:
  - name: Stijn Van Hulle
    github: stijnvanhulle
compatibility:
  kubb: ">=5.0.0"
  node: ">=22"
tags:
  - cypress
  - e2e-testing
  - api-testing
  - test-generation
  - codegen
  - openapi
dependencies:
  - plugin-ts
resources:
  documentation: https://kubb.dev/plugins/plugin-cypress
  repository: https://github.com/kubb-labs/plugins
  issues: https://github.com/kubb-labs/plugins/issues
  changelog: https://github.com/kubb-labs/plugins/blob/main/packages/plugin-cypress/CHANGELOG.md
  codesandbox: https://codesandbox.io/p/github/kubb-labs/plugins/main/examples/cypress
---

# @kubb/plugin-cypress

`@kubb/plugin-cypress` turns your OpenAPI operations into typed `cy.request()` wrappers, one helper per operation. Each helper types its path params, body, query, and response, so a broken API call fails at compile time instead of in the test runner. Use the helpers in `before` and `beforeEach` hooks to seed data, in custom commands, or in API-only tests.

Each helper takes its parameters as a single grouped options object shaped as `{ body, path, query, headers }`, with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you. A helper resolves to the response body and its return type is `Cypress.Chainable<{Operation}Response>`.

## Installation

::: code-group

```shell [bun]
bun add -d @kubb/plugin-cypress@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-cypress@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-cypress@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-cypress@beta
```

:::

## Dependencies

This plugin depends on [`@kubb/plugin-ts`](/plugins/plugin-ts/) for the request, parameter, and response types it imports. Keep `pluginTs()` in the plugins array.

## Example

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({
      output: {
        path: './cypress',
        barrel: { type: 'named' },
        banner: '/* eslint-disable */',
      },
      group: {
        type: 'tag',
        name: ({ group }) => `${group}Requests`,
      },
    }),
  ],
})
```

```typescript [Using a generated helper]
import { getPetById } from '../gen/cypress/petRequests'

describe('Pet API', () => {
  it('returns the pet by id', () => {
    getPetById({ path: { petId: 1 } }).then((pet) => {
      expect(pet.id).to.eq(1)
    })
  })
})
```

:::

## See also

- [Cypress](https://www.cypress.io/)
- [cy.request()](https://docs.cypress.io/api/commands/request)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-cypress/CHANGELOG.md)
