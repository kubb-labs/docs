---
layout: doc
title: Call operations
description: Use the TanStack Query hooks Kubb generates from your OpenAPI spec.
  Pass typed path, query, and header parameters and read data and error state
  off the hook.
outline: deep
---

# Call operations

`@kubb/plugin-react-query` turns each operation into a hook that wraps the client function from `@kubb/plugin-axios` or `@kubb/plugin-fetch`. Read operations become `useFoo`, write operations become `useFoo` mutations, and every hook is typed from the spec.

> [!IMPORTANT]
> By default the plugin emits only the factory helpers (`queryOptions`, `mutationOptions`, `queryKey`, `mutationKey`). Set [`hooks: true`](/plugins/plugin-react-query/reference/options#hooks) in the plugin options to also generate the `use*` hooks shown below.

## Queries

A query hook takes the operation's grouped request config (`path`, `query`, `headers`, whichever the operation declares) as its first argument and returns a TanStack `UseQueryResult`:

```typescript
import { useGetPetById } from './gen/hooks/useGetPetById'

const { data, error, isLoading } = useGetPetById({ path: { petId: 1n } })
```

The second argument holds two option groups. `query` takes any TanStack Query option plus a `client` to target a specific `QueryClient`. `client` takes per-call request config for the underlying client, such as `baseURL` or `signal`:

```typescript
import { useGetPetById } from './gen/hooks/useGetPetById'

useGetPetById(
  { path: { petId: 1n } },
  {
    query: { staleTime: 60_000 },
    client: { baseURL: 'https://api.example.com/v1' },
  },
)
```

## Factories

Every operation also exports a `queryOptions` factory and a `queryKey` helper, so you can prefetch, seed, or compose outside a hook. The key includes the operation URL and path parameters, followed by query or body values when present:

```typescript
import { useQueryClient } from '@tanstack/react-query'
import { getPetByIdQueryKey, getPetByIdQueryOptions } from './gen/hooks/useGetPetById'

const queryClient = useQueryClient()

await queryClient.prefetchQuery(getPetByIdQueryOptions({ path: { petId: 1n } }))
queryClient.invalidateQueries({ queryKey: getPetByIdQueryKey({ path: { petId: 1n } }) })
```

## Mutations

A mutation hook takes only an options object. The grouped request config is the mutation variable, so you pass it to `mutate` or `mutateAsync`:

```typescript
import { useQueryClient } from '@tanstack/react-query'
import { useDeletePet } from './gen/hooks/useDeletePet'

const queryClient = useQueryClient()

const { mutate } = useDeletePet({
  mutation: { onSuccess: () => queryClient.invalidateQueries() },
})

mutate({ path: { petId: 1n } })
```

A `mutationOptions` factory and `mutationKey` helper are exported next to the hook, mirroring the query factories.

<!--@include: ../../../snippets/how-to/query-errors-transport.md-->

## Customize cache keys

Set [`queryKey`](/plugins/plugin-react-query/reference/options#querykey) to change generated keys. String entries are emitted as source code, so use `JSON.stringify` for a string literal.

```typescript [kubb.config.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({
  queryKey: ({ node }) => [JSON.stringify(node.operationId)],
})
```

> [!WARNING]
> This produces a fixed key such as `['getUserByName']`, independent of arguments. Include relevant path and query parameters in the key when their values identify different resources.

## Load more pages

::tabs

:::tabs-item{label="Configure"}

Configure [`infinite`](/plugins/plugin-react-query/reference/options#infinite) with a query parameter declared by the operation, its initial value, and the response path for the next cursor.

```typescript [kubb.config.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({
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
import { useInfiniteQuery } from '@tanstack/react-query'
import { findPetsByTagsInfiniteQueryOptions } from './gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(
  findPetsByTagsInfiniteQueryOptions({ query: { tags: ['dog'] } }),
)
```

:::

::

## Use suspense

Set `suspense: {}` and `hooks: true` to generate suspense hooks alongside regular hooks. Suspense requires TanStack Query v5 or higher.

::code-group

```typescript [kubb.config.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({ hooks: true, suspense: {} })
```

```typescript [usage.ts]
import { useGetPetByIdSuspense } from './gen/hooks/useGetPetByIdSuspense'

const { data } = useGetPetByIdSuspense({ path: { petId: 1n } })
```

::

## Share hook options

::tabs

:::tabs-item{label="Configure"}

Set [`customOptions`](/plugins/plugin-react-query/reference/options#customoptions) to call one options function from every generated hook.

```typescript [kubb.config.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({
  hooks: true,
  customOptions: {
    importPath: './useCustomHookOptions',
    name: 'useCustomHookOptions',
  },
})
```

:::

:::tabs-item{label="Shared options"}

Place the function where the generated import resolves. Each hook passes `{ hookName, operationId }`. The generated barrel re-exports `HookOptions`.

```typescript [src/gen/hooks/useCustomHookOptions.ts]
import type { HookOptions } from './HookOptions'

export function useCustomHookOptions(
  { hookName }: { hookName: keyof HookOptions; operationId: string },
) {
  if (hookName === 'useGetPetById') {
    return { staleTime: 60_000 } satisfies HookOptions['useGetPetById']
  }
  return {}
}
```

:::

::

Per-call query options override shared options.
