---
layout: doc

title: Custom transport in Kubb - swap the send layer for Fetch and Axios
description: Replace the transport the generated client sends through. Wrap fetch with retries or pass a pre-configured axios instance, while Kubb keeps owning URLs, serialization, and auth.
outline: deep
---

# Custom transport

The client Kubb generates splits into two layers. A shared core builds the URL, serializes the query and body, resolves auth, and runs the interceptors. The transport is the last step: it takes the finished request and sends it. Swap the transport and you change how a request leaves your app without touching anything the core already handled.

You set the transport at runtime on the client, not in `kubb.config.ts`. Plugin options control what gets generated. The transport controls how those generated functions reach the network. The two client plugins expose it differently, so each section below covers its own shape.

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch) takes a transport function.
- [`@kubb/plugin-axios`](/plugins/plugin-axios) takes an axios instance.

## When to reach for it

Most apps never need a custom transport. The defaults send through `globalThis.fetch` and `axios.create()`, and the `auth`, `baseURL`, and `headers` options cover the common cases. Replace the transport when the send itself needs to change:

- Add retries, timeouts, or circuit breaking around every request.
- Route through a runtime-specific HTTP client, such as `undici` on Node or a service-worker proxy in the browser.
- Capture metrics or structured logs for each call.
- Return canned responses in tests without hitting the network.

> [!TIP]
> For per-request concerns like adding a header or reading a response, an interceptor or the [`auth` resolver](/docs/5.x/guides/authentication) is the lighter tool. Reach for a custom transport when you need to own the send.

## Fetch: a transport function

`@kubb/plugin-fetch` types the transport as a function that receives a fully resolved request and returns a result:

```typescript
type Transport = (request: ResolvedRequest) => Promise<TransportResult>

type ResolvedRequest = {
  url: string
  method: string
  headers: Record<string, string>
  body?: BodyInit
  signal?: AbortSignal
  credentials?: RequestCredentials
  fetchOptions?: FetchOptions
  responseType?: ResponseType
}

type TransportResult<TData = unknown> = {
  data: TData
  status: number
  statusText: string
  headers: Headers
  request: Request
  response: Response
}
```

The core hands you a `ResolvedRequest` with the URL already built, the query serialized, the body serialized, and the auth headers in place. Your function sends it and returns the parsed `data` along with the native `request` and `response`, so status, headers, and the raw body stay reachable on the result.

### Wrap the default send

A custom transport can delegate to `fetch` and add behavior around it. This one retries a failed `GET` with exponential backoff:

```typescript
import { client, type Transport } from './gen/clients/.kubb/client'

const withRetry: Transport = async (request) => {
  const maxAttempts = 3

  for (let attempt = 1; ; attempt++) {
    const response = await globalThis.fetch(request.url, {
      method: request.method,
      headers: request.headers,
      body: request.body,
      signal: request.signal,
      credentials: request.credentials,
    })

    if (response.ok || request.method !== 'GET' || attempt === maxAttempts) {
      return {
        data: response.status === 204 ? undefined : await response.clone().json().catch(() => undefined),
        status: response.status,
        statusText: response.statusText,
        headers: response.headers,
        request: new Request(request.url),
        response,
      }
    }

    await new Promise((resolve) => setTimeout(resolve, 2 ** attempt * 100))
  }
}

client.setConfig({ transport: withRetry })
```

`setConfig` updates the shared `client` every generated function imports, so every call now retries. The core still parses `data` off the `TransportResult` you return and turns a non-2xx status into a thrown `ResponseError` when `throwOnError` is on, exactly as the default transport does.

### Mock the network in tests

Because the transport is the only piece that touches the network, a test can replace it with a function that returns a fixed result:

```typescript
import { createClient } from './gen/clients/.kubb/client'
import { getPetById } from './gen/clients/getPetById'

const testClient = createClient({
  transport: async (request) => ({
    data: { id: 1, name: 'Fluffy' },
    status: 200,
    statusText: 'OK',
    headers: new Headers(),
    request: new Request(request.url),
    response: new Response(),
  }),
})

const { data } = await getPetById({ path: { petId: 1 }, client: testClient })
//      ^ { id: 1, name: 'Fluffy' }
```

`createClient` returns an isolated instance bound to your transport, so the test never mutates the shared `client`. Pass it per call with the `client` option, or hand it to a query plugin.

## Axios: a custom instance

`@kubb/plugin-axios` types the transport as an `AxiosInstance`. The default is `axios.create()`, and you replace it with your own pre-configured instance:

```typescript
type ClientConfig = {
  // ...
  transport?: AxiosInstance
}
```

This keeps you on axios's own API for the send, so an instance you already configure elsewhere drops straight in. Kubb still owns the URL, query, body, and auth, then forwards them to the instance as an `AxiosRequestConfig`.

### Pass a pre-configured instance

Give the client an instance with a timeout, default headers, and a logging interceptor:

```typescript
import axios from 'axios'
import { client } from './gen/clients/.kubb/client'

const instance = axios.create({
  timeout: 10_000,
  headers: { 'X-Client': 'kubb' },
})

instance.interceptors.response.use((response) => {
  console.info(`${response.config.method?.toUpperCase()} ${response.config.url} -> ${response.status}`)
  return response
})

client.setConfig({ transport: instance })
```

Every generated function now sends through your instance, so its timeout, headers, and interceptors apply to each call.

> [!NOTE]
> Kubb sets `transformRequest`, `paramsSerializer`, and `validateStatus` on each request so its own serialization and `throwOnError` handling stay in charge. Configure cross-cutting concerns like timeouts, retries, and interceptors on the instance instead of overriding those fields.

### Add retries with a plugin

Because the transport is a real axios instance, axios plugins work on it. Wire up [`axios-retry`](https://github.com/softonic/axios-retry) on the instance you pass as the transport:

```typescript
import axios from 'axios'
import axiosRetry from 'axios-retry'
import { createClient } from './gen/clients/.kubb/client'

const instance = axios.create({ baseURL: 'https://petstore.swagger.io/v2' })
axiosRetry(instance, { retries: 3, retryDelay: axiosRetry.exponentialDelay })

export const apiClient = createClient({ transport: instance })
```

## Where to set it

A transport rides the same `ClientConfig` as `baseURL` and `auth`, so you set it the same three ways. Pick the one that matches the scope you need.

Call `client.setConfig({ transport })` to cover the whole app at once, since every generated function imports the shared `client`. Call `createClient({ transport })` for an isolated client you pass on the `client` option or hand to a query plugin, which suits tests and talking to more than one backend. Pass the `transport` option on a single request to override both for that one call.

## See also

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
- [Authentication guide](/docs/5.x/guides/authentication)
- [Set your own baseURL](/docs/5.x/guides/base-url)
