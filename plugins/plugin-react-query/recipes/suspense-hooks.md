---
layout: doc
title: Suspense hooks
description: Generate useSuspenseQuery hooks alongside the regular query hooks with @kubb/plugin-react-query.
outline: deep
---

# Suspense hooks

[`suspense`](/plugins/plugin-react-query/reference/options#suspense) is on by default and adds a suspense variant next to each query. Set [`hooks: true`](/plugins/plugin-react-query/reference/options#hooks) to generate `useSuspenseQuery` alongside `useQuery`. This needs TanStack Query v5 or later.

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
      hooks: true,
      suspense: {},
    }),
  ],
})
```

```typescript
import { useSuspenseGetPetById } from './gen/hooks/useGetPetById'

const { data } = useSuspenseGetPetById({ path: { petId: 1 } })
```
