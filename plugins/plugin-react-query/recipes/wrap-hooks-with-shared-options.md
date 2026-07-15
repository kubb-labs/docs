---
layout: doc
title: Wrap every hook with shared options
description: Route every generated hook through your own options function with @kubb/plugin-react-query's customOptions.
outline: deep
---

# Wrap every hook with shared options

Set [`customOptions`](/plugins/plugin-react-query/reference/options#customoptions) to route every generated hook through your own function, so shared behavior like `onSuccess` or `select` stays in one place instead of repeated per call. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

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
      customOptions: {
        importPath: './useCustomHookOptions',
        name: 'useCustomHookOptions',
      },
    }),
  ],
})
```

## Output example

Every generated hook calls `useCustomHookOptions({ hookName, operationId })` and spreads the result into its query/mutation options, and the barrel re-exports your `HookOptions` type so a typed wrapper stays in sync:

```typescript twoslash [src/gen/hooks/useGetPetById.ts]
import { useCustomHookOptions } from './useCustomHookOptions'
import { getPetById } from '../clients/getPetById'
import { queryOptions, useQuery } from '@tanstack/react-query'

export function useGetPetById({ path }, options = {}) {
  const { query: queryConfig = {}, client: config = {} } = options ?? {}
  const resolvedParams = { path: typeof path === 'function' ? path() : path }
  const queryKey = getPetByIdQueryKey(resolvedParams)
  const customOptions = useCustomHookOptions({ hookName: 'useGetPetById', operationId: 'getPetById' })

  return useQuery({
    ...getPetByIdQueryOptions(resolvedParams, config),
    ...customOptions,
    ...queryConfig,
    queryKey,
  })
}
```

```typescript twoslash [usage.ts]
// ./useCustomHookOptions.ts
import type { HookOptions } from './src/gen'

export function useCustomHookOptions({ hookName, operationId }: { hookName: keyof HookOptions; operationId: string }) {
  if (hookName === 'useGetPetById') {
    return { staleTime: 60_000 } satisfies HookOptions['useGetPetById']
  }
  return {}
}
```
