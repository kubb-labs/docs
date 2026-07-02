---
layout: doc
title: Call operations
description: Use the TanStack Query hooks Kubb generates from your OpenAPI spec. Pass typed path, query, and header parameters and read data and error state off the hook.
outline: deep
---

# Call operations

`@kubb/plugin-react-query` turns each operation into a hook that wraps the client function from `@kubb/plugin-axios` or `@kubb/plugin-fetch`. Read operations become `useFoo`, write operations become `useFoo` mutations, and every hook is typed from the spec.

## Queries

A query hook takes the operation's grouped request config (`path`, `query`, `headers`, whichever the operation declares) as its first argument and returns a TanStack `UseQueryResult`:

```typescript
import { useGetPetById } from './gen/hooks/useGetPetById'

const { data, error, isLoading } = useGetPetById({ path: { petId: 1 } })
```

The second argument holds two option groups. `query` takes any TanStack Query option plus a `client` to target a specific `QueryClient`. `client` takes per-call request config for the underlying client, such as `baseURL`, `headers`, or `timeout`:

```typescript
useGetPetById(
  { path: { petId: 1 } },
  {
    query: { staleTime: 60_000, enabled: petId != null },
    client: { headers: { 'X-Trace': 'abc' } },
  },
)
```

## Factories

Every operation also exports a `queryOptions` factory and a `queryKey` helper, so you can prefetch, seed, or compose outside a hook. The key is `[{ url, params }]`, built from the operation path and its path params:

```typescript
import { getPetByIdQueryKey, getPetByIdQueryOptions } from './gen/hooks/useGetPetById'

await queryClient.prefetchQuery(getPetByIdQueryOptions({ path: { petId: 1 } }))
queryClient.invalidateQueries({ queryKey: getPetByIdQueryKey({ path: { petId: 1 } }) })
```

## Mutations

A mutation hook takes only an options object. The grouped request config is the mutation variable, so you pass it to `mutate` or `mutateAsync`:

```typescript
import { useDeletePet } from './gen/hooks/useDeletePet'

const { mutate } = useDeletePet({
  mutation: { onSuccess: () => queryClient.invalidateQueries() },
})

mutate({ path: { petId: 1 } })
```

A `mutationOptions` factory and `mutationKey` helper are exported next to the hook, mirroring the query factories.

<!--@include: ../../../snippets/how-to/query-errors-transport.md-->
