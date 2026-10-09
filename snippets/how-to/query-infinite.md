## Load more pages

Configure `infinite` with a query parameter declared by the operation, its initial value, and the response path for the next cursor. Infinite output needs `hooks: true`, and only operations that declare the `queryParam` receive it.

::tabs

:::tabs-item{label="React Query"}

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

```typescript [usage.ts]
import { useInfiniteQuery } from '@tanstack/react-query'
import { findPetsByTagsInfiniteQueryOptions } from './gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(
  findPetsByTagsInfiniteQueryOptions({ query: { tags: ['dog'] } }),
)
```

:::

:::tabs-item{label="Vue Query"}

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

```typescript [usage.ts]
import { useInfiniteQuery } from '@tanstack/vue-query'
import { findPetsByTagsInfiniteQueryOptions } from './gen/hooks/useFindPetsByTagsInfinite'

const { data, fetchNextPage, hasNextPage } = useInfiniteQuery(
  findPetsByTagsInfiniteQueryOptions({ query: () => ({ tags: ['dog'] }) }),
)
```

:::

::

`nextParam` takes dot notation or an array of keys. Change it to match your API's response. Without `nextParam`, the generated options increment the page number until a page returns an empty array.
