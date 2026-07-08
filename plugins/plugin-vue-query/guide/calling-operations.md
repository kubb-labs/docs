---
layout: doc
title: Call operations
description: Use the TanStack Query composables Kubb generates from your OpenAPI spec, with reactive parameters and typed data and error state.
outline: deep
---

# Call operations

`@kubb/plugin-vue-query` turns each operation into a composable that wraps the client function from `@kubb/plugin-axios` or `@kubb/plugin-fetch`. Read operations become `useFoo`, write operations become `useFoo` mutations, and every composable is typed from the spec.

> [!IMPORTANT]
> By default the plugin emits only the factory helpers (`queryOptions`, `mutationOptions`, `queryKey`, `mutationKey`). Set [`hooks: true`](/plugins/plugin-vue-query/reference/options#hooks) in the plugin options to also generate the `use*` composables shown below.

## Queries

A query composable takes the operation's grouped request config as its first argument. Parameters accept a value, a `ref`, or a getter (`MaybeRefOrGetter`), so the query re-runs when a reactive parameter changes:

```typescript
import { ref } from 'vue'
import { useFindPetsByTags } from './gen/hooks/useFindPetsByTags'

const tags = ref(['dog'])
const { data, error, isLoading } = useFindPetsByTags({ query: () => ({ tags: tags.value }) })
```

The second argument holds two option groups. `query` takes any TanStack Query option plus a `client` to target a specific `QueryClient`. `client` takes per-call request config for the underlying client:

```typescript
import { useFindPetsByTags } from './gen/hooks/useFindPetsByTags'

useFindPetsByTags(
  { query: { tags: ['dog'] } },
  {
    query: { staleTime: 60_000 },
    client: { headers: { 'X-Trace': 'abc' } },
  },
)
```

## Factories

Every query operation also exports a `queryOptions` factory and a `queryKey` helper for prefetching and invalidation. The key is `[{ url }, query]`, built from the operation path and its query params:

```typescript
import { useQueryClient } from '@tanstack/vue-query'
import { findPetsByTagsQueryKey, findPetsByTagsQueryOptions } from './gen/hooks/useFindPetsByTags'

const queryClient = useQueryClient()

await queryClient.prefetchQuery(findPetsByTagsQueryOptions({ query: { tags: ['dog'] } }))
queryClient.invalidateQueries({ queryKey: findPetsByTagsQueryKey({ query: { tags: ['dog'] } }) })
```

Mutations export a `mutationKey` helper next to the composable.

## Mutations

A mutation composable takes only an options object. The grouped request config is the mutation variable, so you pass it to `mutate` or `mutateAsync`:

```typescript
import { useQueryClient } from '@tanstack/vue-query'
import { useUpdatePetWithForm } from './gen/hooks/useUpdatePetWithForm'

const queryClient = useQueryClient()

const { mutate } = useUpdatePetWithForm({
  mutation: { onSuccess: () => queryClient.invalidateQueries() },
})

mutate({ path: { petId: 1 }, query: { name: 'Fluffy' } })
```

<!--@include: ../../../snippets/how-to/query-errors-transport.md-->
