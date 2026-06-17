---
title: 'Migration: @kubb/plugin-client'
description: Configuration and generated-output changes for @kubb/plugin-client when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-client`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-client`](/plugins/plugin-client).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `wrapper` option is renamed to `sdk`.

Class clients (`clientType: 'class'`, `clientType: 'staticClass'`, and `sdk`) now name each tag class with a `Client` suffix. A `pet` tag generates `class PetClient` instead of `class Pet`. The old name collided with the schema model of the same name, so the barrel re-exported both and `tsc` failed with `TS2300: Duplicate identifier`. The suffix keeps the class and model apart.

```ts
// Before
export class Pet { /* ... */ }

// After
export class PetClient { /* ... */ }
```

To keep the previous names, override `resolveGroupName` on the `resolver` option. `this` is bound to the full resolver, so `this.resolveClassName` restores the old behavior.

```ts
pluginClient({
  clientType: 'class',
  resolver: {
    resolveGroupName(name) {
      return this.resolveClassName(name)
    },
  },
})
```

All other options are unchanged.

## Generated output

### Operation type names

The naming scheme dropped the `Mutation` infix and unified status responses under `Status<code>`.

| v4 type                      | v5 type               |
| ---------------------------- | --------------------- |
| `AddPet200`                  | `AddPetStatus200`     |
| `AddPet405`                  | `AddPetStatus405`     |
| `AddPetMutationRequest`      | `AddPetData`          |
| `AddPetMutationResponse`     | `AddPetResponse`      |
| `AddPetMutation` (container) | _removed_ (see below) |
| _did not exist_              | `AddPetResponses`     |
| _did not exist_              | `AddPetRequestConfig` |

The single `AddPetMutation` aggregate is replaced by three explicit types:

```typescript
export type AddPetRequestConfig = {
  data?: AddPetData
  pathParams?: never
  queryParams?: never
  headerParams?: never
  url: '/pet'
}

export type AddPetResponses = {
  '200': AddPetStatus200
  '405': AddPetStatus405
}

export type AddPetResponse = AddPetStatus200 | AddPetStatus405
```

**GET operation example:**

```typescript
export type GetPetQueryParams = { limit?: number; offset?: number }
export type GetPetRequestConfig = {
  data?: never
  pathParams?: { petId: string }
  queryParams?: GetPetQueryParams
  headerParams?: never
  url: '/pet/{petId}'
}
export type GetPetResponses = { '200': Pet; '404': ErrorResponse }
export type GetPetResponse = Pet | ErrorResponse
```

This naming pattern applies consistently across all HTTP methods and is inherited by `plugin-react-query`, `plugin-vue-query`, `plugin-cypress`, `plugin-msw`, and `plugin-mcp`.

### Client return type narrows to 2xx responses

The generic on the generated client function now references the union of `2xx` response status types (`AddPetStatus200`) instead of the full response alias (`AddPetResponse`). The returned `Promise` resolves to the success body only. Non-`2xx` responses surface through the client's error path.

```diff
- const res = await request<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
+ const res = await request<AddPetStatus200, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
```

`AddPetResponse`, `AddPetResponses`, and the per-status `AddPetStatus<code>` aliases are still emitted by `plugin-ts`. Only the generic threaded into the client changes.

This matches the default behavior of axios, ky, and Kubb's bundled fetch client, which all throw on non-`2xx`. If you pass raw native `fetch` without a throwing wrapper, narrow with a type guard at the call site or wrap the client to throw on error responses. The previous union type masked the same runtime mismatch.

### Bundled client runtime exports `client`

The bundled HTTP client runtime exports its request function as `client` for both the `axios` and `fetch` adapters. The name is consistent across bundled and non-bundled output (`@kubb/plugin-client/clients/fetch`, `@kubb/plugin-client/clients/axios`, and the generated `.kubb/client.ts`), so the root barrel re-exports a valid `client` symbol. The bundled file is always written to `.kubb/client.ts`. Earlier, `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-mcp` emitted `.kubb/fetch.ts`.

Generated code imports the runtime as a default import, so most projects need no changes. If you import the request function as a named export, rename it to `client`:

```diff
- import { fetch } from '@kubb/plugin-client/clients/fetch'
+ import { client } from '@kubb/plugin-client/clients/fetch'
```

The default import can still bind to any local name:

```typescript
import client from '@kubb/plugin-client/clients/fetch'
```
