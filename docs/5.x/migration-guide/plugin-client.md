---
title: 'Migration: @kubb/plugin-client'
description: Configuration and generated-output changes for @kubb/plugin-client when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-client`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-client`](/plugins/plugin-client).

[`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver) replaces `transformers.name`, and `wrapper` is renamed to `sdk`.

Class clients (`clientType: 'class'`, `clientType: 'staticClass'`, and `sdk`) now name each tag class with a `Client` suffix. A `pet` tag generates `class PetClient` instead of `class Pet`. The old name collided with the schema model of the same name, so the barrel re-exported both and `tsc` failed with `TS2300: Duplicate identifier`. The suffix keeps the class and the model apart.

```typescript [Generated output]
// Before
export class Pet { /* ... */ }

// After
export class PetClient { /* ... */ }
```

To keep the previous names, override `resolveGroupName` on the `resolver` option. `this` is bound to the full resolver, so `this.resolveClassName` restores the old behavior.

```typescript [v5 kubb.config.ts]
pluginClient({
  clientType: 'class',
  resolver: {
    resolveGroupName(name) {
      return this.resolveClassName(name)
    },
  },
})
```

The `bundle` option is removed. The selected `client` always bundles into `.kubb/client.ts`, the behavior `bundle: true` used to opt into. Drop `bundle` from your config, and from the `client` sub-option of `plugin-react-query`, `plugin-vue-query`, `plugin-swr`, and `plugin-mcp`. To import the client from an external module instead of bundling it, set [`importPath`](/plugins/plugin-client#importpath).

```diff [Diff]
  pluginClient({
    client: 'fetch',
-   bundle: true,
  })
```

Projects that relied on the old default (`bundle: false`, which imported from `@kubb/plugin-client/clients/{client}`) now get a self-contained `.kubb/client.ts` and no longer need `@kubb/plugin-client` at runtime. To keep importing from the package, point `importPath` at it.

## Removed: `paramsType`, `pathParamsType`, `paramsCasing`

These three options are gone. Every generated function now takes a single grouped options object shaped as `{ body, path, query, headers }` with camelCase property names, the same shape `@kubb/plugin-fetch` already used. There is no inline variant and no casing switch. The request still sends the original parameter names from the spec, and Kubb writes that mapping for you.

```diff [Diff]
  pluginClient({
-   paramsType: 'object',
-   pathParamsType: 'object',
-   paramsCasing: 'camelcase',
  })
```

The call signature changes from positional arguments to one object:

```typescript [Generated output]
// Before (paramsType: 'inline')
export async function getPet(petId: string, params?: GetPetQueryParams, config = {}) {}
await getPet('pet_1', { status: 'available' })

// After
export async function getPet({ path, query, headers, body }: GetPetRequestConfig, config = {}) {}
await getPet({ path: { petId: 'pet_1' }, query: { status: 'available' } })
```

All other options are unchanged.

## Generated output

### Operation type names

The naming scheme drops the `Mutation` infix and groups status responses under `Status<code>`.

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

```typescript [Generated output]
export type AddPetRequestConfig = {
  body: AddPetData
  path?: never
  query?: never
  headers?: never
  url: '/pet'
}

export type AddPetResponses = {
  '200': AddPetStatus200
  '405': AddPetStatus405
}

export type AddPetResponse = AddPetStatus200 | AddPetStatus405
```

The same pattern for a GET operation:

```typescript [Generated output]
export type GetPetQueryParams = { limit?: number; offset?: number }
export type GetPetRequestConfig = {
  body?: never
  path?: { petId: string }
  query?: GetPetQueryParams
  headers?: never
  url: '/pet/{petId}'
}
export type GetPetResponses = { '200': Pet; '404': ErrorResponse }
export type GetPetResponse = Pet | ErrorResponse
```

This naming pattern applies across all HTTP methods, and `plugin-react-query`, `plugin-vue-query`, `plugin-cypress`, `plugin-msw`, and `plugin-mcp` inherit it.

### Client return type narrows to 2xx responses

The generic on the generated client function now references the union of `2xx` response status types (`AddPetStatus200`) instead of the full response alias (`AddPetResponse`). The returned `Promise` resolves to the success body only. Non-`2xx` responses surface through the client's error path.

```diff [Diff]
- const res = await request<AddPetResponse, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
+ const res = await request<AddPetStatus200, ResponseErrorConfig<AddPetStatus405>, AddPetData>({ ... })
```

`AddPetResponse`, `AddPetResponses`, and the per-status `AddPetStatus<code>` aliases are still emitted by `plugin-ts`. Only the generic threaded into the client changes.

This matches the default behavior of axios, ky, and Kubb's bundled fetch client, which all throw on non-`2xx`. If you pass raw native `fetch` without a throwing wrapper, narrow with a type guard at the call site or wrap the client to throw on error responses. The previous union type masked the same runtime mismatch.

### Bundled client runtime exports `client`

The HTTP client runtime exports its request function as `client` for both the `axios` and `fetch` adapters, whether bundled into `.kubb/client.ts` or imported from `@kubb/plugin-client/clients/{axios,fetch}`. When bundled it lands at `.kubb/client.ts` and the root barrel re-exports that `client`. In v4, `@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, and `@kubb/plugin-mcp` emitted `.kubb/fetch.ts`.

Generated code imports the runtime as a default import, so most projects need no changes. Rename the named export to `client` if you import the request function that way.

```diff [Diff]
- import { fetch } from '@kubb/plugin-client/clients/fetch'
+ import { client } from '@kubb/plugin-client/clients/fetch'
```

The default import can still bind to any local name.

```typescript [Update imports]
import client from '@kubb/plugin-client/clients/fetch'
```
