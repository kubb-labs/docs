---
layout: doc

title: Fetch Client - Native Fetch API
description: Use Kubb's Fetch client for native browser API calls. Configuration, TypeScript types, and request/response handling.
outline: deep
---

# Swap in a Fetch client

`@kubb/plugin-fetch` generates one HTTP client function per operation on top of the global [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch). It needs no extra runtime dependency. Register `@kubb/plugin-axios` instead when you want axios.

See [plugins/plugin-fetch](/plugins/plugin-fetch).

## Create `kubb.config.ts`

Add `pluginFetch` to the plugins list. It reads its types from `@kubb/plugin-ts`, so register that too.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginFetch } from '@kubb/plugin-fetch'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig(() => {
  return {
    root: '.',
    input: {
      path: './petStore.yaml',
    },
    output: {
      path: './src/gen',
      clean: true,
    },
    adapter: adapterOas(),
    plugins: [
      pluginTs({
        output: { path: 'models.ts' },
      }),
      pluginFetch({
        output: {
          path: '.',
        },
        baseURL: 'https://petstore.swagger.io/v2',
      }),
    ],
  }
})
```

## View the generated code

Every operation becomes a typed function. Each function takes the grouped options object and returns the success response body.

```typescript [src/gen/models.ts]
import client from './client.ts'
import type { GetPetByIdQueryResponse, GetPetByIdRequestConfig } from './models.ts'

/**
 * @description Returns a single pet
 * @summary Find pet by ID
 * @link /pet/:petId
 */
export async function getPetById(
  { path }: Omit<GetPetByIdRequestConfig, 'url'>,
  config: Partial<Parameters<typeof client>[0]> = {},
): Promise<GetPetByIdQueryResponse> {
  const res = await client<GetPetByIdQueryResponse>({ method: 'GET', url: `/pet/${path.petId}`, ...config })
  return res.data
}
```
