---
layout: doc
title: Infinite scroll query
description: Generate useInfiniteQuery hooks for cursor-based pagination with @kubb/plugin-react-query.
outline: deep
---

# Infinite scroll query

Set [`infinite`](/plugins/plugin-react-query/reference/options#infinite) to generate `useInfiniteQuery` hooks, naming the cursor query parameter, the first page value, and the path to the next cursor on the response. Infinite hooks are only emitted for operations whose query parameters actually contain `infinite.queryParam` by name, so pick a value that matches a real parameter in your schema.

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
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
      },
    }),
  ],
})
```

## Output example

The PetStore fixture's `findPetsByTags` operation has a `page` query parameter, not `next_page`, so the snippet below uses `queryParam: 'page'` to actually trigger infinite-hook generation for it. Pick whatever name matches your own schema.

```typescript [src/gen/hooks/useFindPetsByTagsInfinite.ts]
import type { ResponseErrorConfig } from '../.kubb/client'
import type { FindPetsByTagsOptions, FindPetsByTagsQuery, FindPetsByTagsStatus200, FindPetsByTagsStatus400 } from '../types/FindPetsByTags'
import type { InfiniteData } from '@tanstack/react-query'
import { findPetsByTags } from '../clients/findPetsByTags'
import { infiniteQueryOptions } from '@tanstack/react-query'

export const findPetsByTagsInfiniteQueryKey = ({ query }: Omit<FindPetsByTagsOptions, 'headers'> = {}) => [{ url: '/pet/findByTags' }, ...(query ? [query] : [])] as const

export function findPetsByTagsInfiniteQueryOptions({ query }: FindPetsByTagsOptions = {}, config = {}) {
  const queryKey = findPetsByTagsInfiniteQueryKey({ query })
  return infiniteQueryOptions<FindPetsByTagsStatus200, ResponseErrorConfig<FindPetsByTagsStatus400>, InfiniteData<FindPetsByTagsStatus200>, typeof queryKey, NonNullable<FindPetsByTagsQuery['page']>>({
    queryKey,
    queryFn: async ({ signal, pageParam }) => {
      query = { ...(query ?? {}), ['page']: pageParam as unknown as FindPetsByTagsQuery['page'] } as FindPetsByTagsQuery
      const { data } = await findPetsByTags({ ...config, query, signal: config.signal ?? signal, throwOnError: true })
      return data
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage?.['pagination']?.['next']?.['cursor']
  })
}
```

```typescript [usage.ts]
import { useInfiniteQuery } from '@tanstack/react-query'
import { findPetsByTagsInfiniteQueryOptions } from './src/gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage } = useInfiniteQuery(findPetsByTagsInfiniteQueryOptions({ query: { tags: ['dog'] } }))
```
