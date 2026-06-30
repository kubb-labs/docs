# Error handling

The client Kubb generates has one rule that shapes every failure: a non-2xx response either throws
or lands on the result, and you choose which with `throwOnError`. It defaults to `true`, so a
resolved call always means success and you read `data` without a guard. Turn it off and the same
call resolves for every status, with the failure on `error`.

This holds for both [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and [`@kubb/plugin-axios`](/plugins/plugin-axios/). The transport differs, the
error contract does not.

## Throw on a non-2xx response

By default a status outside 200-299 throws a `ResponseError`. Wrap the call in a `try`/`catch`
and read the parsed body and status off the error:

```typescript
import { getPetById } from './gen/clients/getPetById'
import { ResponseError } from './gen/clients/.kubb/client'

try {
  const { data } = await getPetById({ path: { petId: 1 } })
  console.info(data.name)
} catch (error) {
  if (error instanceof ResponseError) {
    console.error(error.status) // 404
    console.error(error.data) // the parsed error body
  }
}
```

A `ResponseError` carries the same fields a result does, so nothing about the response is out of
reach:

```typescript
class ResponseError extends Error {
  data: TError // the parsed error body
  status: number
  statusText: string
  contentType: string | undefined
  request: Request // AxiosRequestConfig on plugin-axios
  response: Response // AxiosResponse on plugin-axios
}
```

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

## Set the default for every call

`throwOnError` reads from three places, narrowest first: the per-call option, then the client
config, then the built-in default of `true`. Set it on the client to flip the default for the
whole app while keeping the per-call override:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({ throwOnError: false })

// resolves with an error result
const list = await searchPets({ query: { status: 'available' }, throwOnError: false })

// opt one call back into throwing
const pet = await getPetById({ path: { petId: 1 }, throwOnError: true })
```

## Network failures still throw

`throwOnError` governs the response status, not the send. A request that never gets a response,
from a dropped connection, DNS failure, or an aborted `AbortSignal`, rejects whatever the setting.
A `ResponseError` means the server answered with a non-2xx. Any other rejection means the request
did not complete.

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
import { ParseError } from './gen/clients/.kubb/standardSchema'

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

## See also

- [Call operations](/plugins/plugin-fetch/guide/calling-operations)
- [Serialization](/plugins/plugin-fetch/guide/serialization)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
- [Custom transport](/plugins/plugin-fetch/guide/transport)
