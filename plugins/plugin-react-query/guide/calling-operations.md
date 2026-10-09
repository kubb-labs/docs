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

<!--@include: ../../../snippets/how-to/query-keys.md-->

<!--@include: ../../../snippets/how-to/query-infinite.md-->

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

Per-call query options override shared options.
