---
layout: doc

title: Fetch Client - Native Fetch API
description: Use Kubb's Fetch client for native browser API calls. Configuration, TypeScript types, and request/response handling.
outline: deep
---

# Swap in a Fetch client

`@kubb/plugin-client` bundles two runtimes. Set `client: 'axios'` (the default) or `client: 'fetch'`, and the plugin writes that client to `.kubb/client.ts`.

To bring your own client, set `importPath` instead. The generated code imports the HTTP runtime from there, and nothing is bundled. Use this for [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch), [Ky](https://github.com/sindresorhus/ky), or any wrapper you maintain.

## Create `kubb.config.ts`

Point `importPath` at a relative path, an import alias, or a package name. The plugin uses the value as-is.

See [plugins/plugin-client](/plugins/plugin-client).

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'
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
      pluginClient({
        output: {
          path: '.',
        },
        importPath: '../client.ts', // [!code ++]
      }),
    ],
  }
})
```

## Add `client.ts`

Every HTTP request (GET, PUT, PATCH, POST, DELETE) calls the default export from your `importPath`. Kubb passes a `RequestConfig`, modeled on the Axios request interface.

> [!IMPORTANT]
> The client must return an object shaped like `ResponseConfig`. This holds even when `dataReturnType` is `'data'` and the generated function returns only `res.data`.

```typescript [client.ts]
export type RequestConfig<TData = unknown> = {
  url?: string
  method: 'GET' | 'PUT' | 'PATCH' | 'POST' | 'DELETE'
  params?: object
  data?: TData | FormData
  responseType?: 'arraybuffer' | 'blob' | 'document' | 'json' | 'text' | 'stream'
  signal?: AbortSignal
  headers?: HeadersInit
}

export type ResponseConfig<TData = unknown> = {
  data: TData
  status: number
  statusText: string
}

export type Client = <TData, _TError = unknown, TVariables = unknown>(config: RequestConfig<TVariables>) => Promise<ResponseConfig<TData>>

export const client = async <TData, TError = unknown, TVariables = unknown>(config: RequestConfig<TVariables>): Promise<ResponseConfig<TData>> => {
  const response = await fetch('https://example.org/post', {
    method: config.method.toUpperCase(),
    body: JSON.stringify(config.data),
    signal: config.signal,
    headers: config.headers,
  })

  const data = await response.json()

  return {
    data,
    status: response.status,
    statusText: response.statusText,
  }
}
```

## View the generated code

```typescript [src/gen/models.ts]
import client from '../client.ts'
import type { ResponseConfig } from '../client.ts'
import type { GetPetByIdQueryResponse, GetPetByIdPathParams } from './models.ts'

/**
 * @description Returns a single pet
 * @summary Find pet by ID
 * @link /pet/:petId
 */
export async function getPetById(
  petId: GetPetByIdPathParams['petId'],
  options: Partial<Parameters<typeof client>[0]> = {},
): Promise<ResponseConfig<GetPetByIdQueryResponse>['data']> {
  const res = await client<GetPetByIdQueryResponse>({ method: 'get', url: `/pet/${petId}`, ...options })
  return res.data
}
```
