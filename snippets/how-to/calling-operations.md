# Call operations

The generated client accepts grouped request options on every operation and returns a typed `RequestResult` by default. The Fetch and Axios clients share the calling convention below.

## Call an operation

Pass parameters under `path`, `query`, `headers`, `cookies`, or `body`, matching the OpenAPI operation.

```typescript
import { getPetById } from './gen/clients/getPetById'

const { data } = await getPetById({ path: { petId: 1 } })
//      ^ the parsed pet, typed from the 200 response
```

Query, header, and cookie parameters sit under their own keys, and a request body goes under
`body`:

```typescript
import { searchPets } from './gen/clients/searchPets'
import { updatePet } from './gen/clients/updatePet'

await searchPets({
  query: { status: 'available', category: 'dogs', limit: 10, offset: 0 },
})

await updatePet({
  path: { petId: '123' },
  headers: { 'X-Request-ID': 'req-123456' },
  body: { name: 'Updated name', status: 'sold' },
})
```

Each key is optional and only appears when the operation declares it, so an operation with no
parameters is called with an empty object, `getStatus({})`. The serialization guide covers how
Kubb encodes arrays and objects in each location.

## Read the result

A resolved call returns a `RequestResult` discriminated by the numeric `status`:

```typescript
type RequestResult = {
  status: number
  data: TData // the parsed success body, undefined on an error result
  error: TError // the parsed error body, undefined on a success result
  contentType: string | undefined // the negotiated response media type
  request: Request // the native request (AxiosRequestConfig on plugin-axios)
  response: Response // the native response (AxiosResponse on plugin-axios)
}
```

When `throwOnError` is `true` (the generated default), a resolved call is always a success, so you
read `data` straight away:

```typescript
const { data, status, response } = await getPetById({ path: { petId: 1 } })

console.info(status) // 200
console.info(response.headers.get('x-ratelimit-remaining'))
```

When an operation documents more than one success status, narrow on `status` to reach the body
for that case, and TypeScript follows the check:

```typescript
const result = await getPetById({ path: { petId: 1 } })

if (result.status === 200) {
  console.info(result.data.name)
}
```

The error handling guide covers reading the `error` body and handling failures.

## Unwrap the success body

Call `.unwrap()` to return the success body. Awaiting the operation directly returns the full result.

```typescript
import { getPetById } from './gen/clients/getPetById'

const pet = await getPetById({ path: { petId: 1 } }).unwrap()
//    ^ the parsed pet, not the full RequestResult
```

How `unwrap()` handles a failure depends on `throwOnError`. With `throwOnError: true`, a non-2xx
response already throws a `ResponseError` before the call resolves, so `unwrap()` throws the same
`ResponseError` a plain `await` would:

```typescript
import { ResponseError } from './gen/.kubb/client'

try {
  const pet = await getPetById({ path: { petId: 1 } }).unwrap()
} catch (error) {
  if (ResponseError.is(error)) {
    console.error(error.status) // 404
  }
}
```

With `throwOnError: false`, `.unwrap()` rejects with the parsed error body instead of a `ResponseError`:

```typescript
try {
  const pet = await getPetById({ path: { petId: 1 }, throwOnError: false }).unwrap()
} catch (error) {
  // the parsed error body, not a ResponseError
  console.error(error)
}
```

## Set the content type

When an operation accepts or returns more than one media type, set `contentType` on the call. A
bare string sets the request content type. The object form also sends an `Accept` header for the
response:

```typescript
await uploadAvatar({
  path: { petId: '123' },
  body: avatarBlob,
  contentType: 'image/png',
})

await getPet({
  path: { petId: '123' },
  contentType: { request: 'application/json', response: 'application/xml' },
})
```

For operations that already declare a single content type, Kubb bakes it into the generated
function, so a multipart upload needs only the body:

```typescript
import { uploadFile } from './gen/clients/uploadFile'

// the generated function already sets contentType: { request: 'multipart/form-data' }
await uploadFile({ path: { petId: '123' }, body: { file: pngBlob } })
```

The serialization guide covers how each content type maps to a request body and how a response
body is decoded.

## Pass native client options

Pass `options` on an operation for native transport settings:

```typescript [src/app.ts]
import { getPetById } from './gen/clients/getPetById'

// Axios client
await getPetById({ path: { petId: 1 }, options: { timeout: 5_000 } })
```

For Fetch clients, use options such as `cache`, `mode`, `redirect`, `keepalive`, `duplex`, or `next`. Axios supports `timeout`, `proxy`, `maxRedirects`, `decompress`, and `onUploadProgress`.

Set `client.setConfig({ options })` for shared defaults. Per-call options take precedence. Kubb keeps control of serialization and HTTP error handling, as described in the custom transport guide.

## Build a URL without sending

Use `client.getUrl` to build a URL with the same base URL, path interpolation, and query serialization as a request:

```typescript
import { client } from './gen/.kubb/client'

const url = client.getUrl({
  url: '/pets/{petId}',
  path: { petId: 1 },
  query: { fields: 'name' },
})
// https://api.example.com/v1/pets/1?fields=name
```
