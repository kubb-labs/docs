---
layout: doc
title: Infinite scroll query
description: Generate useInfiniteQuery composables for cursor-based pagination with @kubb/plugin-vue-query.
outline: deep
---

# Infinite scroll query

Set [`infinite`](/plugins/plugin-vue-query/reference/options#infinite) to generate `useInfiniteQuery` hooks, naming the cursor query parameter, the first page value, and the path to the next cursor on the response.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginVueQuery } from '@kubb/plugin-vue-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginVueQuery({
      output: { path: 'hooks', mode: 'directory' },
      infinite: {
        queryParam: 'page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
      },
    }),
  ],
})
```

## Output example

```typescript [src/gen/hooks/useFindPetsByTagsInfinite.ts]
export function findPetsByTagsInfiniteQueryOptions({ query }: { query?: MaybeRefOrGetter<FindPetsByTagsOptions['query']> } = {}, config: Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>> = {}) {
  const queryKey = findPetsByTagsInfiniteQueryKey({ query })
  return infiniteQueryOptions<FindPetsByTagsStatus200, ResponseErrorConfig<FindPetsByTagsStatus400>, InfiniteData<FindPetsByTagsStatus200>, QueryKey, NonNullable<FindPetsByTagsQuery['page']>>({
    queryKey,
    queryFn: async ({ signal, pageParam }) => {
      query = {
        ...(query ?? {}),
        ['page']: pageParam as unknown as FindPetsByTagsQuery['page'],
      } as FindPetsByTagsQuery
      const { data } = await findPetsByTags({ ...config, query: toValue(query), signal: config.signal ?? signal, throwOnError: true })
      return data
    },
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage?.['pagination']?.['next']?.['cursor']
  })
}
```

```typescript [usage.ts]
import { useInfiniteQuery } from '@tanstack/vue-query'
import { findPetsByTagsInfiniteQueryOptions } from './gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(
  findPetsByTagsInfiniteQueryOptions({ query: () => ({ tags: ['dog'] }) }),
)
```
