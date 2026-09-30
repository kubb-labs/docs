---
layout: doc
title: Write your client
description: The module that @kubb/plugin-client imports. Export a client function and two types, then add the behavior your app needs.
outline: deep
---

# Write your client

The generated functions import your module through [`importPath`](/plugins/plugin-client/reference/options#importpath). It is the only runtime code in the picture, and you own all of it.

## Required exports

| Export | Kind | Purpose |
| ------ | ---- | ------- |
| `client` | function | Sends the request. Every generated function calls it, unless a call passes its own `client`. |
| `Options` | type | The grouped options object a generated function accepts. |
| `RequestResult` | type | What a generated function resolves to. |

If your spec has server-sent event operations, also export `toEventStream` and the `EventStreamResult` and `SuccessOf` types.

## What a generated function looks like

```typescript
import type { Options, RequestResult } from '../../../client'
import type { GetPetByIdOptions, GetPetByIdResponses } from '../../models/pet/GetPetById'
import { client } from '../../../client'

export function getPetById<ThrowOnError extends boolean = true>(
  options: Options<GetPetByIdOptions, ThrowOnError>,
): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'GET',
    url: '/pet/{petId}',
    security: [{ type: 'apiKey', name: 'api_key', in: 'header' }, { type: 'oauth2' }],
    ...config,
    throwOnError: config.throwOnError ?? true,
  }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
}
```

Your `client` receives `method`, the `url` template with `{param}` placeholders, `security`, the grouped `path`, `query`, `headers`, and `body`, and `throwOnError`. It returns a promise.

## A minimal client

The client below uses `fetch`. Replace the transport with the HTTP library you use.

```typescript [src/client.ts]
export type RequestConfig = {
  method: 'GET' | 'PUT' | 'PATCH' | 'POST' | 'DELETE' | 'OPTIONS' | 'HEAD'
  url: string
  baseURL?: string
  headers?: object
  path?: object
  query?: object
  body?: unknown
  signal?: AbortSignal
  throwOnError?: boolean
  security?: Array<{ type: string; name?: string; in?: string }>
  client?: typeof client
}

type DataShape = { body?: unknown; headers?: unknown; path?: unknown; query?: unknown }

export type Options<TData extends DataShape, ThrowOnError extends boolean = true> = Omit<RequestConfig, keyof DataShape | 'url' | 'method'> &
  TData & { throwOnError?: ThrowOnError }

export type RequestResult<TResponses, ThrowOnError extends boolean = true> = ThrowOnError extends true
  ? { data: TResponses[keyof TResponses]; error: undefined; response: Response }
  : { data: TResponses[keyof TResponses]; error: undefined; response: Response } | { data: undefined; error: {}; response: Response }

// Set this to your API host. `new URL()` needs an absolute URL.
export const settings = { baseURL: 'https://petstore3.swagger.io/api/v3' }

export async function client(config: RequestConfig) {
  const path: Record<string, unknown> = { ...config.path }
  const url = new URL((config.baseURL ?? settings.baseURL) + config.url.replace(/\{(\w+)\}/g, (_, key) => encodeURIComponent(String(path[key]))))

  const response = await fetch(url, {
    method: config.method,
    headers: config.headers as Record<string, string>,
    body: config.body === undefined ? undefined : JSON.stringify(config.body),
    signal: config.signal,
  })
  const body = await response.json().catch(() => undefined)

  if (response.ok) return { data: body, error: undefined, response }
  if (config.throwOnError ?? true) throw new Error(`Request failed with status ${response.status}`)
  return { data: undefined, error: body ?? { status: response.status }, response }
}
```

The [example project](https://github.com/kubb-labs/plugins/tree/main/examples/client) has a fuller version with a base URL setter, query handling, and an async auth hook. Type the response map with the status-aware helpers you need. This sketch keeps them simple on purpose.

> [!TIP]
> Start small. Add retries, interceptors, or request signing to `client` when you need them. Kubb does not depend on any of it.
