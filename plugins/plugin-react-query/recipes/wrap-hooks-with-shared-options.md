---
layout: doc
title: Wrap every hook with shared options
description: Route every generated hook through your own options function with @kubb/plugin-react-query's customOptions.
outline: deep
---

# Wrap every hook with shared options

Set [`customOptions`](/plugins/plugin-react-query/reference/options#customoptions) to route every generated hook through your own function, so shared behavior like `onSuccess` or `select` stays in one place instead of repeated per call. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

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

Every generated hook calls `useCustomHookOptions({ hookName, operationId })` and spreads the result into its query/mutation options. The barrel also re-exports your `HookOptions` type:

```typescript [src/gen/hooks/useGetPetById.ts]
import { useCustomHookOptions } from './useCustomHookOptions'
import { getPetById } from '../clients/getPetById'
import { queryOptions, useQuery } from '@tanstack/react-query'

export function useGetPetById({ path }, options = {}) {
  const { query: queryConfig = {}, client: config = {} } = options ?? {}
  const { client: queryClient, ...resolvedOptions } = queryConfig
  const resolvedParams = { path: typeof path === 'function' ? path() : path }
  const queryKey = resolvedOptions?.queryKey ?? getPetByIdQueryKey(resolvedParams)
  const customOptions = useCustomHookOptions({ hookName: 'useGetPetById', operationId: 'getPetById' })

  const queryResult = useQuery({
    ...getPetByIdQueryOptions(resolvedParams, config),
    ...customOptions,
    ...resolvedOptions,
    queryKey,
  }, queryClient)

  queryResult.queryKey = queryKey

  return queryResult
}
```

```typescript [usage.ts]
// ./useCustomHookOptions.ts
import type { HookOptions } from './src/gen'

export function useCustomHookOptions({ hookName, operationId }: { hookName: keyof HookOptions; operationId: string }) {
  if (hookName === 'useGetPetById') {
    return { staleTime: 60_000 } satisfies HookOptions['useGetPetById']
  }
  return {}
}
```
