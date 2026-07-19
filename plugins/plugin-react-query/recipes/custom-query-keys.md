---
layout: doc
title: Custom query keys
description: Control the queryKey array a useQuery hook uses for caching and invalidation with @kubb/plugin-react-query.
outline: deep
---

# Custom query keys

Pass a [`queryKey`](/plugins/plugin-react-query/reference/options#querykey) builder to control the array TanStack Query uses to cache and invalidate a hook's data.

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
      queryKey: ({ node }) => [JSON.stringify(node.operationId)],
    }),
  ],
})
```

This turns `getUserByName`'s key into a fixed `['getUserByName'] as const`, independent of its call arguments.

## Output example

```typescript [src/gen/hooks/useGetUserByName.ts]
import type { RequestConfig, ResponseErrorConfig } from '../.kubb/client'
import type { GetUserByNameOptions, GetUserByNameStatus200, GetUserByNameStatus400, GetUserByNameStatus404 } from '../types/GetUserByName'
import { getUserByName } from '../clients/getUserByName'
import { queryOptions } from '@tanstack/react-query'

export const getUserByNameQueryKey = ({ path }: Omit<GetUserByNameOptions, 'headers'>) => ["getUserByName"] as const

type GetUserByNameQueryKey = ReturnType<typeof getUserByNameQueryKey>

export function getUserByNameQueryOptions({ path }: GetUserByNameOptions, config: Partial<Omit<RequestConfig, 'path' | 'query' | 'body' | 'headers' | 'url'>> = {}) {
  const queryKey = getUserByNameQueryKey({ path })
  return queryOptions<GetUserByNameStatus200, ResponseErrorConfig<GetUserByNameStatus400 | GetUserByNameStatus404>, GetUserByNameStatus200, typeof queryKey>({
   queryKey,
   queryFn: async ({ signal }) => {
      const { data } = await getUserByName({ ...config, path, signal: config.signal ?? signal, throwOnError: true })
      return data
   },
  })
}
```

```typescript [usage.ts]
import { useQuery } from '@tanstack/react-query'
import { getUserByNameQueryOptions } from './src/gen/hooks/useGetUserByName'

const { data } = useQuery(getUserByNameQueryOptions({ path: { username: 'fehguy' } }))
```
