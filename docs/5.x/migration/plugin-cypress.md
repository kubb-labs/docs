---
title: 'Migration: @kubb/plugin-cypress'
description: Changes for @kubb/plugin-cypress when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-cypress`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-cypress`](/plugins/plugin-cypress/).

[`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The `generators` option is [gone](/docs/5.x/migration#generators-removed).

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone. Each request helper now takes a single grouped options object shaped as `{ body, path, query, headers }`. Its `path`, `query`, and `headers` members are the `@kubb/plugin-ts` `*Options` sub-types, so their property names are the ones from the OpenAPI document.

```diff [Diff]
  pluginCypress({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

The helper signature changes from positional arguments to one object. The first argument is the grouped options type that `@kubb/plugin-ts` generates for the operation (for example `ShowPetByIdOptions`). When an operation has a required parameter in a group, that group (`path`, `query`, or `headers`) is required too. The trailing `options` argument, typed `Partial<Cypress.RequestOptions>`, is unchanged.

::: code-group

```diff [Call site]
-showPetById(2, { limit: 10 })
+showPetById({ path: { petId: 2 }, query: { limit: 10 } })
```

```diff [Generated output]
-export function showPetById(petId: number, query?: ShowPetByIdQueryParams, options = {}) {}
+export function showPetById({ path, query }: ShowPetByIdOptions, options: Partial<Cypress.RequestOptions> = {}) {}
```

:::

## Removed: `dataReturnType`

`dataReturnType` is gone. Every helper now yields the response body, typed `Cypress.Chainable<T>`, so the `'data'` and `'full'` choice no longer applies.

```diff [Diff]
  pluginCypress({
-   dataReturnType: 'data',
  })
```

`baseURL` stays the same, and `exclude`, `include`, and `override` keep their v4 shape. Cypress has no `validator` option, unlike the client plugins.

## Generated output

Two things change. HTTP method constants are now uppercase (`'post'` becomes `'POST'`), and imports follow the new `*Options` / `*Response` naming.

```diff [Diff]
- import type { AddPetMutationRequest, AddPetMutationResponse } from '../../models/AddPet.ts'
- export function addPet(data: AddPetMutationRequest): Cypress.Chainable<AddPetMutationResponse> {
-   return cy.request<AddPetMutationResponse>({
-     method: 'post',
-     url: 'http://localhost:3000/pet',
+ import type { AddPetOptions, AddPetResponse } from '../../models.ts'
+ export function addPet({ body }: AddPetOptions, options: Partial<Cypress.RequestOptions> = {}): Cypress.Chainable<AddPetResponse> {
+   return cy.request<AddPetResponse>({
+     method: 'POST',
+     url: `http://localhost:3000/pet`,
```
