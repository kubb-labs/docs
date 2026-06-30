---
layout: doc

title: Call operations with the generated client - Fetch and Axios
description: Call the functions Kubb generates from your OpenAPI spec. Pass typed path, query, header, cookie, and body parameters, then read the status, data, and native response off one result.
outline: deep
---

# Call operations

[`@kubb/plugin-fetch`](/plugins/plugin-fetch) and [`@kubb/plugin-axios`](/plugins/plugin-axios) turn each operation in your OpenAPI spec into a
typed function. The two plugins generate different transports but share one calling convention, so
the code on this page reads the same whichever you pick. Swap the import and the examples still
hold.

Every operation takes a single grouped options object and returns one `RequestResult`. The
parameters are typed from the spec, and the result carries the status, the parsed body, and the
native request and response.

## Call an operation

Import the generated function and pass the parameters it declares. Kubb groups them by where they
belong in the request: `path`, `query`, `headers`, `cookies`, and `body`.

```typescript
import { getPetById } from './gen/clients/getPetById'

const { data } = await getPetById({ path: { petId: 1 } })
//      ^ the parsed pet, typed from the 200 response
```

A path like `/pets/{petId}/photos/{photoId}` takes each segment under `path`:

```typescript
import { getPetPhoto } from './gen/clients/getPetPhoto'

const { data } = await getPetPhoto({
  path: { petId: '123', photoId: '456' },
})
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
parameters is called with no arguments. How Kubb encodes arrays and objects in each location is
covered in [serialization](/docs/5.x/guide/going-further/serialization).

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

With the default `throwOnError`, a resolved call is always a success, so you read `data`
straight away:

```typescript
const { data, status, response } = await getPetById({ path: { petId: 1 } })

console.info(status) // 200
console.info(response.headers.get('x-ratelimit-remaining'))
```

When an operation documents more than one success status, narrow on `status` to reach the body
for that case. TypeScript follows the check:

```typescript
const result = await getPetById({ path: { petId: 1 } })

if (result.status === 200) {
  console.info(result.data.name)
}
```

Reading the `error` body and handling failures is covered in
[error handling](/docs/5.x/guide/going-further/error-handling).

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

How each content type maps to a request body, and how a response body is decoded, lives in
[serialization](/docs/5.x/guide/going-further/serialization).

## Reuse one configuration

Every generated function imports a shared `client`. Call `setConfig` once at startup and every
call picks up the change:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  baseURL: 'https://api.example.com/v1',
  headers: { 'X-Client': 'web' },
})
```

For an isolated client that does not touch the shared one, build a separate instance with
`createClient` and pass it on the `client` option of any call. This suits tests and talking to
more than one backend:

```typescript
import { createClient } from './gen/clients/.kubb/client'
import { getPetById } from './gen/clients/getPetById'

const staging = createClient({ baseURL: 'https://staging.example.com/v1' })

await getPetById({ path: { petId: 1 }, client: staging })
```

The configuration object is the same `ClientConfig` in both cases. `baseURL`, `auth`, and the
transport each have their own guide, linked below.

## Build a URL without sending

`client.getUrl` returns the URL for a call without making the request. It runs the same
`baseURL`, path interpolation, and query serialization as the send path, so it suits building a
link or logging the target ahead of a request:

```typescript
import { client } from './gen/clients/.kubb/client'

const url = client.getUrl({
  url: '/pets/{petId}',
  path: { petId: 1 },
  query: { fields: 'name' },
})
// https://api.example.com/v1/pets/1?fields=name
```

## See also

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
- [Error handling](/docs/5.x/guide/going-further/error-handling)
- [Serialization](/docs/5.x/guide/going-further/serialization)
- [Server-sent events](/docs/5.x/guide/going-further/server-sent-events)
- [Set your own baseURL](/docs/5.x/guide/going-further/base-url)
- [Authentication](/docs/5.x/guide/going-further/authentication)
- [Custom transport](/docs/5.x/guide/going-further/transport)
