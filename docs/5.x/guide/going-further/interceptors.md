---
layout: doc

title: Interceptors in the generated client - hook into every request and response
description: Run code on every call the Kubb client makes. Add or rewrite headers before the send, observe or transform the response, react to errors, and register, replace, or remove handlers at runtime.
outline: deep
---

# Interceptors

An interceptor runs on every call the client makes, without touching the generated functions or
the spec. The client exposes three channels on `client.interceptors`: `request` runs before the
send, `response` runs after it, and `error` runs when a call throws. Reach for one when a concern
cuts across every request, such as a trace header, request logging, or a token refresh on `401`.

The channels carry a different payload on each transport. [`@kubb/plugin-fetch`](/plugins/plugin-fetch) hands you the
resolved request and result as plain objects, while [`@kubb/plugin-axios`](/plugins/plugin-axios) wraps axios's own
interceptor managers, so a handler there receives the native axios config, response, and error.
The examples below show both.

## Run before the send

A request interceptor sees the request after the core has built the URL, serialized the query and
body, and resolved auth, so you change what leaves the app as a last step. Return the request to
pass it on.

::: code-group

```typescript [Fetch]
import { client } from './gen/clients/.kubb/client'

client.interceptors.request.use((request) => {
  request.headers['X-Request-ID'] = crypto.randomUUID()
  return request
})
```

```typescript [Axios]
import { client } from './gen/clients/.kubb/client'

client.interceptors.request.use((request) => {
  request.headers.set('X-Request-ID', crypto.randomUUID())
  return request
})
```

:::

On fetch the handler receives a `ResolvedRequest` (`url`, `method`, `headers`, `body`, `signal`,
`credentials`, `options`, `responseType`). On axios it receives an `InternalAxiosRequestConfig`,
so headers go through `AxiosHeaders` and the body is on `data`.

## Run after the send

A response interceptor sees every result before the call resolves, so it is the place to log,
collect metrics, or reshape a body across the board. On fetch it runs before the success or error
split and before any deserializer, so `result.data` is still the raw body.

::: code-group

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

:::

The fetch handler receives a `TransportResult` (`data`, `status`, `statusText`, `headers`,
`contentType`, `request`, `response`), the axios handler an `AxiosResponse`.

## React to an error

An error interceptor runs when a non-2xx throws, which happens while `throwOnError` is on. Use it
to log a failure or kick off a token refresh so the next call picks up the new credential.

::: code-group

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

:::

The fetch handler receives the `ResponseError`, the axios handler an `AxiosError`. This channel
only fires on the throw path. When you read with `throwOnError: false`, the call resolves and no
error interceptor runs, so inspect the returned `error` on the result instead. See
[error handling](/docs/5.x/guide/going-further/error-handling) for that path.

## Add, replace, and remove handlers

`use` registers a handler and returns an id. Pass that id to `eject` to remove it, or to `update`
to swap its function in place. Handlers run in the order they were registered.

```typescript
const id = client.interceptors.request.use((request) => request)

client.interceptors.request.update(id, (request) => {
  request.headers['X-Trace'] = 'on'
  return request
})

client.interceptors.request.eject(id)
```

## Where to set them

Interceptors live on a client instance, not on a single call. Register them on the shared `client`
every generated function imports to cover the whole app. For an isolated instance from
[`createClient`](/docs/5.x/guide/going-further/calling-operations#reuse-one-configuration), set
them on that instance, and they stay scoped to the calls you pass it to.

## See also

- [Call operations](/docs/5.x/guide/going-further/calling-operations)
- [Error handling](/docs/5.x/guide/going-further/error-handling)
- [Authentication](/docs/5.x/guide/going-further/authentication)
- [Custom transport](/docs/5.x/guide/going-further/transport)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
