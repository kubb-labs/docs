---
title: 'Migration: @kubb/plugin-cypress'
description: Changes for @kubb/plugin-cypress when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-cypress`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). For the full option reference, see [`@kubb/plugin-cypress`](/plugins/plugin-cypress).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone. Each request helper now takes a single grouped options object shaped as `{ body, path, query, headers }` with camelCase property names. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

```diff [Diff]
  pluginCypress({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

The helper signature changes from positional arguments to one object:

```typescript [Generated output]
// Before
showPetById(2, { limit: 10 })

// After
showPetById({ path: { petId: 2 }, query: { limit: 10 } })
```

## Generated output

Two things change. HTTP method constants are now uppercase (`'post'` becomes `'POST'`), and imports follow the new `*Data` / `*Response` naming.

```diff [Diff]
- import type { AddPetMutationRequest, AddPetMutationResponse } from '../../models/AddPet.ts'
- export function addPet(data: AddPetMutationRequest): Cypress.Chainable<AddPetMutationResponse> {
-   return cy.request<AddPetMutationResponse>({
-     method: 'post',
-     url: 'http://localhost:3000/pet',
+ import type { AddPetData, AddPetResponse } from '../../models.ts'
+ export function addPet(data: AddPetData): Cypress.Chainable<AddPetResponse> {
+   return cy.request<AddPetResponse>({
+     method: 'POST',
+     url: `http://localhost:3000/pet`,
```
