---
layout: doc
title: Custom query keys
description: Control the queryKey array a useQuery hook uses for caching and invalidation with @kubb/plugin-react-query.
outline: deep
---

# Custom query keys

Pass a [`queryKey`](/plugins/plugin-react-query/reference/options#querykey) builder to control the array TanStack Query uses to cache and invalidate a hook's data. The callback receives the operation node and returns the key array, and string values are inlined verbatim, so wrap a literal in `JSON.stringify(...)`.

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
      queryKey: ({ node }) => [JSON.stringify(node.operationId)],
    }),
  ],
})
```

This turns `getUserByName`'s key into a fixed `['getUserByName'] as const`, independent of its call arguments.
