# Handle errors

The generated client throws on non-2xx responses by default. Set the generated default on the client plugin. Individual operations can override it:

```typescript
import { getPetById } from './gen/clients/getPetById'
import { ResponseError } from './gen/.kubb/client'

try {
  const { data } = await getPetById({ path: { petId: 1 } })
  console.info(data.name)
} catch (error) {
  if (ResponseError.is(error)) {
    console.error(error.status) // 404
    console.error(error.data) // the parsed error body
  }
}
```

A `ResponseError` includes the HTTP method and URL (without query parameters, keeping credentials safe) in its `message`, e.g. `GET https://api.example.com/pets/1 failed with status 404 Not Found`.

The error exposes these fields:

```typescript
class ResponseError extends Error {
  static is(error: unknown): error is ResponseError<unknown, unknown, unknown>
  data: TError // the parsed error body
  status: number
  statusText: string
  contentType: string | undefined
  request: Request // AxiosRequestConfig on plugin-axios
  response: Response // AxiosResponse on plugin-axios
}
```

Use `ResponseError.is(error)` to narrow errors across generated packages, which each bundle their own class. It checks the error name.

## Return the error instead

Pass `throwOnError: false` and the call resolves for every documented status. The result is a
discriminated union: `data` is set on success and `error` on failure, so branch on `status` or
check which field is present.

```typescript
const result = await getPetById({ path: { petId: 1 }, throwOnError: false })

if (result.error) {
  console.error(result.status, result.error)
} else {
  console.info(result.data.name)
}
```

Check `status` to narrow responses to a specific documented status code.

## Set the generated default

Set `throwOnErrorDefault` on the client plugin to choose how generated operations handle non-2xx
responses by default. Each call can still override that setting with `throwOnError`:

```typescript
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ throwOnErrorDefault: false })

// resolves with an error result
const list = await searchPets({ query: { status: 'available' } })

// opt one call back into throwing
const pet = await getPetById({ path: { petId: 1 }, throwOnError: true })
```

The generated operation passes its selected value to the client runtime, so setting
`throwOnError` with `client.setConfig` does not change this default. Configure the plugin to
change the generated default.

## Network failures still throw

> [!IMPORTANT]
> `throwOnError` governs the response status, not the send: a dropped connection, DNS failure, or
> aborted `AbortSignal` rejects regardless of the setting. A `ResponseError` means the server
> answered with a non-2xx, and anything else means the request never completed.

```typescript
try {
  const { data } = await getPetById({ path: { petId: 1 }, throwOnError: false })
  use(data)
} catch (error) {
  // not a ResponseError: the request never completed
  console.error('request failed to send', error)
}
```

Pass an `AbortSignal` to cancel a request. The call rejects with the abort reason.

## Validation failures

When you turn on the `validator` option, a body that does not match its schema throws a
`ParseError` instead of returning. It carries the raw `issues` from the schema, so the same
handling works across Zod, valibot, and arktype:

```typescript
import { ParseError } from './gen/.kubb/standardSchema'

try {
  const { data } = await getPetById({ path: { petId: 1 } })
  use(data)
} catch (error) {
  if (error instanceof ParseError) {
    console.error(error.issues) // [{ message, path }]
  }
}
```

A `ParseError` reports schema validation issues. A `ResponseError` reports a non-2xx status. On the non-throwing path, configured error schemas validate the error body separately from success schemas.

Calling `.unwrap()` on a `throwOnError: false` call turns that same `error` into a rejection, so a
`try`/`catch` works there too.
