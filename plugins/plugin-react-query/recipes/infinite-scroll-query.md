---
layout: doc
title: Infinite scroll query
description: Generate useInfiniteQuery hooks for cursor-based pagination with @kubb/plugin-react-query.
outline: deep
---

# Infinite scroll query

Set [`infinite`](/plugins/plugin-react-query/reference/options#infinite) to generate `useInfiniteQuery` hooks, naming the cursor query parameter, the first page value, and the path to the next cursor on the response.

```typescript twoslash [kubb.config.ts]
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
      infinite: {
        queryParam: 'next_page',
        initialPageParam: 0,
        nextParam: 'pagination.next.cursor',
      },
    }),
  ],
})
```
