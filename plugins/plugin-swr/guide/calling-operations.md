---
layout: doc
title: Call operations
description: Use the SWR hooks Kubb generates from your OpenAPI spec. Queries fetch with typed parameters, and mutations pass their input through trigger.
outline: deep
---

# Call operations

`@kubb/plugin-swr` turns each operation into an SWR hook that wraps the client function from `@kubb/plugin-axios` or `@kubb/plugin-fetch`. Read operations become `useFoo` with `useSWR`, write operations become `useFoo` with `useSWRMutation`, and every hook is typed from the spec.

## Queries

A query hook takes the operation's grouped request config (`path`, `query`, `headers`, whichever the operation declares) as its first argument:

```typescript
import { useGetPetById } from './gen/hooks/useGetPetById'

const { data, error, isLoading } = useGetPetById({ path: { petId: 1 } })
```

The second argument holds the SWR configuration plus Kubb-specific switches. `query` takes any `SWRConfiguration`, `client` takes per-call request config for the underlying client, `shouldFetch: false` makes the key `null` so SWR skips the request, and `immutable: true` disables revalidation:

```typescript
useGetPetById(
  { path: { petId: 1 } },
  {
    query: { refreshInterval: 30_000 },
    client: { headers: { 'X-Trace': 'abc' } },
    shouldFetch: petId != null,
  },
)
```

The key is built by the exported `queryKey` helper as `[{ url, params }]`, so you can also match it from `mutate` for cache updates.

## Mutations

A mutation hook takes only an options object. The grouped request config travels through `trigger(...)` as the mutation argument:

```typescript
import { useCreatePet } from './gen/hooks/useCreatePet'

const { trigger, isMutating } = useCreatePet({
  mutation: { onSuccess: () => mutate(getPetsQueryKey()) },
})

await trigger({ body: { name: 'Fluffy' } })
```

A `mutationKey` helper is exported next to the hook, and `shouldFetch: false` sets the key to `null` so the mutation cannot fire.

<!--@include: ../../../snippets/how-to/query-errors-transport.md-->
