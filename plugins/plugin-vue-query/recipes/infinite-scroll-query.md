---
layout: doc
title: Infinite scroll query
description: Generate useInfiniteQuery composables for cursor-based pagination with @kubb/plugin-vue-query.
outline: deep
---

# Infinite scroll query

Set [`infinite`](/plugins/plugin-vue-query/reference/options#infinite) to generate `useInfiniteQuery` hooks, naming the cursor query parameter, the first page value, and the path to the next cursor on the response.

```typescript twoslash [kubb.config.ts]
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
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
      },
    }),
  ],
})
```
