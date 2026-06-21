---
title: Client contract
description: The shared RequestResult contract behind @kubb/plugin-axios and @kubb/plugin-fetch. Covers the grouped options, the result shape, throwOnError, the bundled runtime, and validation.
layout: doc
outline: [2, 3]
---

# Client contract

`@kubb/plugin-axios` and `@kubb/plugin-fetch` generate the same code against one shared contract. Each operation becomes a function that takes a grouped options object and returns a `RequestResult`. The runtime that backs it is bundled into the generated output, so the only difference between the two plugins is the transport (axios or the global `fetch`).

The query plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`) and `@kubb/plugin-mcp` call these generated functions, so they speak the same contract. Register one client plugin and the rest follow it.

## Grouped options

Every generated function takes a single options object. The request parts are grouped under `path`, `query`, `headers`, and `body`, with camelCase property names. Kubb maps them back to the original wire names for you.

```typescript
await getPetById({ path: { petId: 1 } })
await findPetsByStatus({ query: { status: 'available' } })
await addPet({ body: { name: 'doggo' } })
```

The same object also carries per-call request configuration alongside the groups: `throwOnError`, `headers`, `signal`, `baseURL`, `transport`, `querySerializer`, `bodySerializer`, and `auth`.

## RequestResult

A call resolves to a `RequestResult` of `{ data, error, request, response }`.

`throwOnError` defaults to `true`, so a resolved call always means the request succeeded. `data` holds the success body, and a failed request throws a `ResponseError`.

```typescript
const { data } = await getPetById({ path: { petId: 1 } })
//      ^? Pet
```

Pass `throwOnError: false` per call to get the discriminated `{ data?, error? }` form instead. Branch on `error` and read `response.status` yourself.

```typescript
const { data, error, response } = await getPetById({ path: { petId: 1 }, throwOnError: false })
if (error) {
  console.error(response.status)
} else {
  data // the success body
}
```

A thrown failure is a `ResponseError` (exported as `ResponseError`, with the `ResponseErrorConfig` type alias). It carries the parsed `error` payload plus the `request` and `response`.

## The bundled runtime

The runtime is always written to `.kubb/client.ts` in the output. There is no `bundle` option and nothing to install for the contract itself (axios needs `axios` at runtime, and fetch uses the global `fetch`).

The module exports a ready-to-use `client` plus a `createClient` factory. Configure the shared instance with `client.setConfig(...)`, or build an isolated one with `client.createClient(...)`.

```typescript
import { client } from './.kubb/client'

client.setConfig({ baseURL: 'https://petstore.swagger.io/v2' })
```

`ClientConfig` accepts `baseURL`, `headers`, `throwOnError`, `transport`, `querySerializer`, `bodySerializer`, and `auth`. The same fields work per call on the options object, where they override the instance config.

- `transport` swaps the underlying sender: an axios instance for `@kubb/plugin-axios`, a fetch-compatible function for `@kubb/plugin-fetch`.
- `querySerializer` / `bodySerializer` control how the query string and body are encoded. The defaults are exported as `defaultQuerySerializer` and `defaultBodySerializer`.
- `auth` is a callback that returns the credential for each security scheme the operation requires.
- `client.interceptors.request` / `client.interceptors.response` / `client.interceptors.error` register hooks around every call.

## Validation

Set `parser: 'zod'` to validate responses with schemas from `@kubb/plugin-zod`. Only success responses are validated. Opt into request validation with `parser: { request: 'zod', response: 'zod' }`, which checks the request body and query parameters before the call.

## Macros

`macros` rewrites each operation's AST node before it is printed, so you can adjust the generated function without forking the plugin. Build one with `ast.defineMacro` and pass it through `macros`.

## Choosing axios or fetch

Both plugins expose the same options and emit the same contract. Pick `@kubb/plugin-axios` when you already depend on axios or want its interceptors and instance config. Pick `@kubb/plugin-fetch` for a zero-dependency client on the platform `fetch`. Register exactly one so the query and mcp plugins auto-detect it, or set `client: 'axios' | 'fetch'` on those plugins to choose when both are present.
