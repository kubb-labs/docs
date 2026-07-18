---
layout: doc
title: Suspense hooks
description: Generate useSuspenseQuery hooks alongside the regular query hooks with @kubb/plugin-react-query.
outline: deep
---

# Suspense hooks

[`suspense`](/plugins/plugin-react-query/reference/options#suspense) adds a suspense variant next to each query. It is off by default, so set `suspense: {}` to turn it on, and pair it with [`hooks: true`](/plugins/plugin-react-query/reference/options#hooks) to generate `useSuspenseQuery` alongside `useQuery`. This needs TanStack Query v5 or later.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginReactQuery({
      output: { path: 'hooks', mode: 'directory' },
      hooks: true,
      suspense: {},
    }),
  ],
})
```

```typescript
import { useGetPetByIdSuspense } from './src/gen/hooks/useGetPetByIdSuspense'

const { data } = useGetPetByIdSuspense({ path: { petId: 1n } })
```

## Output example

```typescript [src/gen/hooks/useGetPetByIdSuspense.ts]
import type { GetPetByIdOptions, GetPetByIdStatus200, GetPetByIdStatus400, GetPetByIdStatus404 } from '../types/GetPetById'
import type { QueryKey, QueryClient, UseSuspenseQueryOptions, UseSuspenseQueryResult } from '@tanstack/react-query'
import { getPetById } from '../clients/getPetById'
import { queryOptions, useSuspenseQuery } from '@tanstack/react-query'

export const getPetByIdSuspenseQueryKey = ({ path }: Omit<GetPetByIdOptions, 'headers'>) => [{ url: '/pet/:petId', params: path }] as const

export function useGetPetByIdSuspense<TData = GetPetByIdStatus200, TQueryKey extends QueryKey = ReturnType<typeof getPetByIdSuspenseQueryKey>>(
  { path }: { path: GetPetByIdOptions['path'] | (() => GetPetByIdOptions['path']) },
  options: { query?: Partial<UseSuspenseQueryOptions<GetPetByIdStatus200, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>, TData, TQueryKey>> & { client?: QueryClient }, client?: object } = {},
) {
  // ...builds queryKey/queryOptions, then calls useSuspenseQuery(...)
}
```

```typescript [usage.ts]
import { useGetPetByIdSuspense } from './src/gen/hooks/useGetPetByIdSuspense'
import { useGetPetById } from './src/gen/hooks/useGetPetById'

// petId is typed bigint (int64 format), so pass a BigInt literal
const { data } = useGetPetByIdSuspense({ path: { petId: 1n } })
const { data: regular } = useGetPetById({ path: { petId: 1n } })
```
