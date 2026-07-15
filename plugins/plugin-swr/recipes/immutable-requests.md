---
layout: doc
title: Immutable requests
description: Fetch data that never changes once loaded by passing immutable to a generated SWR hook.
outline: deep
---

# Immutable requests

`@kubb/plugin-swr` generates a `useFoo` hook whose second argument accepts a Kubb-specific `immutable` switch. Set it to `true` for data that never changes once loaded, so SWR fetches the resource once and skips revalidation on stale, focus, and reconnect.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginSwr } from '@kubb/plugin-swr'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs(), pluginFetch(), pluginSwr()],
})
```

```typescript
import { useGetPetById } from './gen/hooks/useGetPetById'

const { data } = useGetPetById({ path: { petId: 1 } }, { immutable: true })
```

## Output example

```typescript twoslash [src/gen/hooks/useGetPetById.ts]
export function useGetPetById({ path }: GetPetByIdOptions, options: {
  query?: SWRConfiguration<GetPetByIdResponse, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>>,
  client?: Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>>,
  shouldFetch?: boolean,
  immutable?: boolean
} = {}) {
  const { query: queryOptions, client: config = {}, shouldFetch = true, immutable } = options ?? {}

  const queryKey = getPetByIdQueryKey({ path })

  return useSWR<GetPetByIdResponse, ResponseErrorConfig<GetPetByIdStatus400 | GetPetByIdStatus404>, GetPetByIdQueryKey | null>(
   shouldFetch ? queryKey : null,
   {
     ...getPetByIdQueryOptions({ path }, config),
     ...(immutable ? {
         revalidateIfStale: false,
         revalidateOnFocus: false,
         revalidateOnReconnect: false
       } : { }),
     ...queryOptions,
   }
  )
}
```

```typescript twoslash [usage.ts]
import { useGetPetById } from './gen/hooks/useGetPetById'

// Fetched once, then never revalidated on stale, focus, or reconnect
const { data, error } = useGetPetById({ path: { petId: 1 } }, { immutable: true })
```
