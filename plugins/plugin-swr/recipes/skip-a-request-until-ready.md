---
layout: doc
title: Skip a request until ready
description: Use shouldFetch on a generated SWR hook to hold off a request until its parameters are ready.
outline: deep
---

# Skip a request until ready

`@kubb/plugin-swr` generates a `useFoo` hook whose second argument accepts a Kubb-specific `shouldFetch` switch. Set it to `false` to make the key `null`, so SWR skips the request until the value the hook depends on is ready.

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

const petId: number | undefined = undefined

const { data } = useGetPetById(
  { path: { petId: petId ?? 0 } },
  { shouldFetch: petId != null },
)
```
