# Interceptors

Register handlers on `client.interceptors.request`, `.response`, or `.error` to apply behavior across calls. Fetch handlers receive resolved request/result objects. Axios handlers receive native Axios objects.

## Run before the send

Request handlers run after URL construction, serialization, and authentication. Return the modified request:

::code-group

```typescript [Fetch]
import { client } from './gen/.kubb/client'

client.interceptors.request.use((request) => {
  request.headers['X-Request-ID'] = crypto.randomUUID()
  return request
})
```

```typescript [Axios]
import { client } from './gen/.kubb/client'

client.interceptors.request.use((request) => {
  request.headers.set('X-Request-ID', crypto.randomUUID())
  return request
})
```

::

On fetch the handler receives a `ResolvedRequest` (`url`, `method`, `headers`, `body`, `signal`,
`credentials`, `options`, `responseType`). On axios it receives an `InternalAxiosRequestConfig`,
so headers go through `AxiosHeaders` and the body is on `data`.

## Run after the send

Response handlers run before calls resolve. Fetch handlers run before the status split and deserialization, so `data` is the raw body.

::code-group

```typescript [Fetch]
client.interceptors.response.use((result) => {
  console.info(`${result.status} ${result.request.url}`)
  return result
})
```

```typescript [Axios]
client.interceptors.response.use((response) => {
  console.info(`${response.status} ${response.config.url}`)
  return response
})
```

::

The fetch handler receives a `TransportResult` (`data`, `status`, `statusText`, `headers`,
`contentType`, `request`, `response`), the axios handler an `AxiosResponse`.

## React to an error

Use an error handler to react to HTTP errors on the throwing path:

::code-group

```typescript [Fetch]
client.interceptors.error.use((error) => {
  if (error.status === 401) scheduleTokenRefresh()
  return error
})
```

```typescript [Axios]
client.interceptors.error.use((error) => {
  if (error.response?.status === 401) scheduleTokenRefresh()
  return error
})
```

::

The fetch handler receives the `ResponseError`, the axios handler an `AxiosError`, and this
channel only fires on the throw path. When you read with `throwOnError: false`, a documented
non-2xx response resolves and no error interceptor runs, so inspect the returned `error` on the
result instead. A transport failure (no response at all) still throws on both, but only axios
fires the error channel for it, since the channel is wired directly into its own rejection
handling, while fetch has no result to hand the interceptor stacks. See
[error handling](/plugins/plugin-fetch/guide/error-handling) for that path.

## Add, replace, and remove handlers

`use` registers a handler and returns an id. Pass that id to `eject` to remove it, or to `update`
to swap its function in place.

> [!NOTE]
> Response and error handlers run in the order they were registered,
> and so do request handlers on `plugin-fetch`, but `plugin-axios` delegates to axios, which runs
> them in reverse registration order.

```typescript
const id = client.interceptors.request.use((request) => request)

client.interceptors.request.update(id, (request) => {
  request.headers['X-Trace'] = 'on'
  return request
})

client.interceptors.request.eject(id)
```

## Where to set them

Register handlers on the shared `client` for all operations, or on a separate `createClient` instance for isolated calls. Interceptors are instance-level settings.

On `@kubb/plugin-axios`, interceptors registered through `client.interceptors` also follow a custom
transport set later with `client.setConfig({ transport })`. When the transport changes, handlers
detach from the old instance and attach to the new one, and their IDs stay valid for `eject` and
`update`. Clearing the transport (`client.setConfig({ transport: undefined })`) moves them back to the
client's base instance. A per-call `transport` still bypasses client interceptors.

## See also

- [Call operations](/plugins/plugin-fetch/guide/calling-operations)
- [Error handling](/plugins/plugin-fetch/guide/error-handling)
- [Authentication](/plugins/plugin-fetch/guide/authentication)
- [Custom transport](/plugins/plugin-fetch/guide/transport)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
