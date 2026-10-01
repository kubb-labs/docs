# Error handling

Generated clients use `throwOnError` to handle non-2xx responses. Its generated default is `true`,
so a resolved call means success and you can read `data` without a guard. Set
`throwOnErrorDefault` on the client plugin to change that default for generated operations, or set
`throwOnError` on one call to override it. When it is `false`, the call resolves for every
documented status and puts failures on `error`.

This holds for both [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and [`@kubb/plugin-axios`](/plugins/plugin-axios/). The transport differs, the
error contract does not.

## Throw on a non-2xx response

When `throwOnError` is `true` (the generated default), a status outside 200-299 throws a
`ResponseError`. Wrap the call in a `try`/`catch` and read the parsed body and status off the
error:

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

It carries the same fields a result does, so nothing about the response is out of
reach:

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

> [!TIP]
> Prefer `ResponseError.is(error)` over `error instanceof ResponseError`. Because each generated client bundles its own `.kubb/client.ts`, an application that consumes multiple generated clients has separate `ResponseError` classes. `ResponseError.is` checks `error.name === 'ResponseError'` and safely narrows across package boundaries.

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

Branching on `status` narrows the body to the variant for that code, which matters when the error
responses differ between, say, a 404 and a 422:

```typescript
const result = await updatePet({
  path: { petId: '123' },
  body: { name: 'Updated name' },
  throwOnError: false,
})

switch (result.status) {
  case 200:
    return result.data
  case 404:
    return notFound(result.error)
  case 422:
    return showValidationErrors(result.error)
}
```

## Set the generated default

Set `throwOnErrorDefault` on `@kubb/plugin-fetch` or `@kubb/plugin-axios` to choose how generated
operations handle non-2xx responses by default. Each call can still override that setting with
`throwOnError`:

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

`throwOnError` governs the response status, not the send: a dropped connection, DNS failure, or
aborted `AbortSignal` rejects regardless of the setting. A `ResponseError` means the server
answered with a non-2xx, and anything else means the request never completed.

```typescript
try {
  const { data } = await getPetById({ path: { petId: 1 }, throwOnError: false })
  use(data)
} catch (error) {
  // not a ResponseError: the request never completed
  console.error('request failed to send', error)
}
```

To cancel a request yourself, pass an `AbortSignal` and abort it. The pending call rejects with
the abort reason:

```typescript
const controller = new AbortController()
setTimeout(() => controller.abort(), 5_000)

await searchPets({ query: { status: 'available' }, signal: controller.signal })
```

## Validation failures

When you turn on the [`validator`](/plugins/plugin-fetch/guide/serialization) option, a body
that does not match its schema throws a `ParseError` instead of returning. It carries the raw
`issues` from the schema, so the same handling works across Zod, valibot, and arktype:

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

A `ParseError` is separate from a `ResponseError`: the response arrived and its status was fine,
but the body did not match the schema. Validation runs after the status check, so on the
`throwOnError: false` path a non-2xx never reaches response validation.

Calling `.unwrap()` on a `throwOnError: false` call turns that same `error` into a rejection, so a
`try`/`catch` works there too. See
[unwrap the success body](/plugins/plugin-fetch/guide/calling-operations#unwrap-the-success-body).

## See also

- [Call operations](/plugins/plugin-fetch/guide/calling-operations)
- [Serialization](/plugins/plugin-fetch/guide/serialization)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
- [Custom transport](/plugins/plugin-fetch/guide/transport)
