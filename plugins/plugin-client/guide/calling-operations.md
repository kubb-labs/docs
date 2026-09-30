---
layout: doc
title: Call operations
description: Call the functions Kubb generates from your OpenAPI spec. Pass typed path, query, header, and body parameters, and read the result your client returns.
outline: deep
---

# Call operations

Each generated function takes one grouped options object and returns your client's promise.

```typescript
import { addPet, getPetById } from './gen/clients'

const created = await addPet({ body: { name: 'Odie', photoUrls: [] } })
console.log(created.data, created.response.status)

const pet = await getPetById({ path: { petId: 1n } })
```

The keys are `path`, `query`, `headers`, and `body`. Kubb types each from the spec, so a wrong key or value fails at compile time.

## Errors

`throwOnError` defaults to `true` (see [`throwOnErrorDefault`](/plugins/plugin-client/reference/options#throwonerrordefault)). What that means is up to your client. With the example client, a non-2xx status throws, and `throwOnError: false` returns the error as a value:

```typescript
const result = await getPetById({ path: { petId: 1n }, throwOnError: false })

if (result.error !== undefined) {
  console.log('failed', result.response.status)
} else {
  console.log('pet', result.data.name)
}
```

## Use a different client for one call

Pass `client` to send one call through another function:

```typescript
await getPetById({ path: { petId: 2n }, client: tenantClient })
```
