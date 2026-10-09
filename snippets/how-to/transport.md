# Use a custom transport

Set a transport at runtime to replace the network send. The client still builds URLs, serializes parameters, resolves authentication, and handles results.

Fetch accepts a transport function. Axios accepts an `AxiosInstance`. Use interceptors for request headers or response logging.

## Fetch: a transport function

`@kubb/plugin-fetch` types the transport as a function that receives a fully resolved request and returns a result:

```typescript
type Transport = (request: ResolvedRequest) => Promise<TransportResult>

type ResolvedRequest = {
  url: string
  method: string
  headers: Record<string, string>
  body?: RequestBody
  signal?: AbortSignal
  credentials?: RequestCredentials
  options?: FetchOptions
  responseType?: ResponseType
}

type TransportResult<TData = unknown> = {
  data: TData
  status: number
  statusText: string
  headers: Headers
  contentType?: string
  request: Request
  response: Response
}
```

The core hands you a `ResolvedRequest` with the URL built, the query and body serialized, and auth headers set. Return the parsed `data` along with the native `request` and `response`, so status, headers, and the raw body stay reachable on the result.

### Mock the network in tests

Return a fixed result from an isolated client in tests:

```typescript
import { createClient } from './gen/.kubb/client'
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

Pass the isolated client per operation or to a query plugin.

## Axios: a custom instance

`@kubb/plugin-axios` types the transport as an `AxiosInstance`. The default is `axios.create()`, and you replace it with your own pre-configured instance:

```typescript
type ClientConfig = {
  // ...
  transport?: AxiosInstance
}
```

Kubb forwards the resolved URL, query, body, and authentication to the instance.

### Pass a pre-configured instance

Give the client an instance with a timeout, default headers, and a logging interceptor:

```typescript
import axios from 'axios'
import { client } from './gen/.kubb/client'

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

Every generated function now sends through your instance, so its timeout, headers, and interceptors apply to each call. Any client interceptors registered through `client.interceptors` also transfer to the new transport automatically, preserving their IDs for `eject` and `update`.

> [!NOTE]
> Kubb sets `transformRequest`, `paramsSerializer`, and `validateStatus` on each request so its own serialization and `throwOnError` handling stay in charge. Configure cross-cutting concerns like timeouts, retries, and interceptors on the instance instead of overriding those fields. For a native axios field on a single call, such as `timeout` or `onUploadProgress`, pass `options` on the call instead of building a new instance.

## Where to set it

Use `client.setConfig({ transport })` for shared configuration, `createClient({ transport })` for an isolated instance, or pass `transport` on an operation to override it for one call.
