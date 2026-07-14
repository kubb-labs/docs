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
