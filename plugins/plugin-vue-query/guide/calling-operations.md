---
layout: doc
title: Call operations
description: Use the TanStack Query composables Kubb generates from your OpenAPI
  spec, with reactive parameters and typed data and error state.
outline: deep
---

# Call operations

`@kubb/plugin-vue-query` turns each operation into a composable that wraps the client function from `@kubb/plugin-axios` or `@kubb/plugin-fetch`. Read operations become `useFoo`, write operations become `useFoo` mutations, and every composable is typed from the spec.

> [!IMPORTANT]
> By default the plugin emits only the factory helpers (`queryOptions`, `queryKey`, `mutationKey`). Set [`hooks: true`](/plugins/plugin-vue-query/reference/options#hooks) in the plugin options to also generate the `use*` composables shown below.

## Queries

A query composable takes grouped request parameters as its first argument. Parameters accept a value, ref, or getter. See [reactive parameters](#refetch-when-parameters-change).

```typescript [usage.ts]
import { useGetPetById } from './gen/hooks/useGetPetById'

const { data, error, isLoading } = useGetPetById({ path: { petId: 1n } })
```

The second argument holds two option groups. `query` takes any TanStack Query option plus a `client` to target a specific `QueryClient`. `client` takes per-call request config for the underlying client:

```typescript
import { useFindPetsByTags } from './gen/hooks/useFindPetsByTags'

useFindPetsByTags(
  { query: { tags: ['dog'] } },
  {
    query: { staleTime: 60_000 },
    client: { baseURL: 'https://api.example.com/v1' },
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

mutate({ path: { petId: 1n }, query: { name: 'Fluffy' } })
```

<!--@include: ../../../snippets/how-to/query-errors-transport.md-->

## Customize cache keys

Set [`queryKey`](/plugins/plugin-vue-query/reference/options#querykey) to change generated keys. String entries are emitted as source code, so use `JSON.stringify` for a string literal.

```typescript [kubb.config.ts]
import { pluginVueQuery } from '@kubb/plugin-vue-query'

pluginVueQuery({
  queryKey: ({ node }) => [JSON.stringify(node.operationId)],
})
```

> [!WARNING]
> This produces a fixed key such as `['getUserByName']`, independent of arguments. Include relevant path and query parameters in the key when their values identify different resources.

## Load more pages

::tabs

:::tabs-item{label="Configure"}

Configure [`infinite`](/plugins/plugin-vue-query/reference/options#infinite) with a query parameter declared by the operation, its initial value, and the response path for the next cursor.

```typescript [kubb.config.ts]
import { pluginVueQuery } from '@kubb/plugin-vue-query'

pluginVueQuery({
  hooks: true,
  infinite: {
    queryParam: 'page',
    initialPageParam: 0,
    nextParam: 'pagination.next.cursor',
  },
})
```

Only operations with a `page` query parameter receive infinite-query output. Change `nextParam` to match your API's response.

:::

:::tabs-item{label="Usage"}

Use the generated factory with TanStack Query:

```typescript [usage.ts]
import { useInfiniteQuery } from '@tanstack/vue-query'
import { findPetsByTagsInfiniteQueryOptions } from './gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(
  findPetsByTagsInfiniteQueryOptions({ query: () => ({ tags: ['dog'] }) }),
)
```

:::

::

## Refetch when parameters change

Enable `hooks: true`, then pass a ref or getter to a generated composable. Parameters accept `MaybeRefOrGetter`. A getter tracks its reactive dependencies.

```typescript [usage.ts]
import { ref } from 'vue'
import { useFindPetsByTags } from './gen/hooks/useFindPetsByTags'

const tags = ref(['dog'])
const { data, error, isLoading } = useFindPetsByTags({
  query: () => ({ tags: tags.value }),
})

tags.value = ['cat']
```

Changing `tags.value` updates the query key and fetches the corresponding resource.
