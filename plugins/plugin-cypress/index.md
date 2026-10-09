---
layout: doc
title: Kubb Cypress Plugin
description: Generates a typed cy.request() wrapper per OpenAPI operation so
  your Cypress tests call the API through generated helpers and catch broken
  calls at compile time.
outline: deep
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

Generate typed `cy.request()` helpers from OpenAPI.

- Grouped `body`, `path`, `query`, and `headers` parameters named after the spec.
- Response bodies typed as `Cypress.Chainable<{Operation}Response>`.

## Installation

::code-group{sync="package-manager"}

```shell [bun]
bun add -d @kubb/plugin-cypress
```

```shell [pnpm]
pnpm add -D @kubb/plugin-cypress
```

```shell [npm]
npm install --save-dev @kubb/plugin-cypress
```

```shell [yarn]
yarn add -D @kubb/plugin-cypress
```

::

## Dependencies

- Add [`pluginTs`](/plugins/plugin-ts/) for request and response types.
- Generated helpers require Cypress v13 or higher.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginCypress({ output: { path: 'cypress', mode: 'directory' } }),
  ],
})
```

```typescript [pet.cy.ts]
import { getPetById } from '../src/gen/cypress/getPetById'

describe('Pet API', () => {
  it('returns the pet by id', () => {
    getPetById({ path: { petId: 1n } }).then((pet) => {
      expect(pet.id).to.eq(1n)
    })
  })
})
```

## Documentation

::card-group

:::card{title="Options" to="/plugins/plugin-cypress/reference/options"}
:::

::

## See also

- [Cypress](https://www.cypress.io/)
- [cy.request()](https://docs.cypress.io/api/commands/request)
- [@kubb/plugin-ts](/plugins/plugin-ts/)
- [Changelog](https://github.com/kubb-labs/plugins/blob/main/packages/plugin-cypress/CHANGELOG.md)
