---
layout: doc
title: Typed request helpers against staging
description: Point the generated Cypress request helpers at a non-production host with the baseURL option.
outline: deep
---

# Typed request helpers against staging

Point the generated helpers at a non-production host with [`baseURL`](/plugins/plugin-cypress/reference/options#baseurl), so every `cy.request()` runs against staging. Keep `pluginTs()` in the array for the request and response types.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginCypress } from '@kubb/plugin-cypress'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginCypress({
      baseURL: 'https://staging.example.com',
    }),
  ],
})
```

Import a helper into a spec and assert on the resolved response body.

```typescript
import { getPetById } from '../src/gen/cypress'

describe('Pet API', () => {
  it('returns the pet by id', () => {
    getPetById({ path: { petId: 1 } }).then((res) => {
      expect(res.id).to.eq(1)
    })
  })
})
```
