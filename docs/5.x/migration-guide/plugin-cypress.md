---
title: 'Migration: @kubb/plugin-cypress'
description: Changes for @kubb/plugin-cypress when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-cypress`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-cypress`](/plugins/plugin-cypress).

The plugin options are unchanged. `transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver).

## Generated output

- HTTP method constants are uppercased (`'post'` → `'POST'`).
- Imports follow the new `*Data` / `*Response` naming.

```diff
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
