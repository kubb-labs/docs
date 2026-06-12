---
layout: doc

title: Fetch Client - Native Fetch API
description: Use Kubb's Fetch client for native browser API calls. Configuration, TypeScript types, and request/response handling.
outline: deep
---

# Use of Fetch

By default, `@kubb/plugin-client` uses the Axios client from `@kubb/plugin-client/templates/axios`, which is based on the Axios instance interface.

Use [Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch) or [Ky](https://github.com/sindresorhus/ky) if you need a custom client.

## Create `kubb.config.ts`

Set `importPath` to a relative path, import alias, or library (default: `@kubb/plugin-client/templates/axios`).

See [plugins/plugin-client](/plugins/plugin-client).

```typescript twoslash
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

All HTTP requests (POST, PUT, GET, PATCH, DELETE) use the `importPath` to invoke your default export.

The request configuration follows the `RequestConfig` type, modeled after the Axios request interface.

> [!IMPORTANT]
> The client must return an object in the shape of `ResponseConfig`, even if you change `dataReturnType` with `dataReturnType: 'data'`.

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

## View generated code

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
