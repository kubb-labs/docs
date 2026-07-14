---
layout: doc
title: Custom query keys
description: Control the queryKey array a useQuery composable uses for caching and invalidation with @kubb/plugin-vue-query.
outline: deep
---

# Custom query keys

Pass a [`queryKey`](/plugins/plugin-vue-query/reference/options#querykey) builder to control the array TanStack Query uses to cache and invalidate a hook's data. The callback receives the operation node and returns the key array, and string values are inlined verbatim, so wrap a literal in `JSON.stringify(...)`.

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
      queryKey: ({ node }) => [JSON.stringify(node.operationId)],
    }),
  ],
})
```

This turns `getUserByName`'s key into a fixed `['getUserByName'] as const`, independent of its call arguments.
