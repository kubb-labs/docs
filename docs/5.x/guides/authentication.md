---
layout: doc

title: Authentication - resolve auth from your OpenAPI spec
description: Kubb reads the security schemes from your OpenAPI spec and attaches them to every generated call. You supply the token through a single auth resolver on the client config, and the runtime places it as a bearer, basic, or apiKey credential.
outline: deep
---

# Authentication

The client plugins read the security schemes from your OpenAPI spec and attach them to every generated call. You supply the token once through an `auth` resolver on the client config, and the runtime places it on the request for you. There is no per-endpoint header wiring and no extra plugin option to set.

This applies to every slim client runtime: [`@kubb/plugin-fetch`](/plugins/plugin-fetch) and [`@kubb/plugin-axios`](/plugins/plugin-axios). They share the same `auth` contract, so the setup below is identical whichever one you generate.

## How it works

Each operation in the spec declares which security schemes it needs, either on the operation itself or through the document's global `security`. Kubb resolves those against `components.securitySchemes` and emits a `security` array on the generated call:

```typescript
export function addPet<ThrowOnError extends boolean = true>(
  options: Options<AddPetRequestConfig, ThrowOnError>,
): Promise<RequestResult<AddPetResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'POST',
    url: '/pet',
    security: [{ type: 'http', scheme: 'bearer' }],
    ...config,
  }) as Promise<RequestResult<AddPetResponses, ThrowOnError>>
}
```

Before the request goes out, the runtime walks that `security` array in order, calls your `auth` resolver for each entry until one returns a token, and places the token on the request. When you do not configure `auth`, the metadata is ignored and nothing changes, so generated code stays inert until you opt in.

## Configure the resolver

Set `auth` on the client config with `setConfig`. The resolver is either a static token or a function that returns one, and the function can be async:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  baseURL: 'https://petstore.swagger.io/v2',
  auth: () => localStorage.getItem('token') ?? undefined,
})
```

Return `undefined` to skip a scheme. The runtime then moves on to the next entry in the `security` array, so an operation that accepts more than one scheme falls through to the first credential you can provide.

## Scheme mapping

The resolver receives the resolved scheme as an `Auth` object, so one resolver can serve every operation and decide what to return per scheme:

```typescript
type Auth = {
  type: 'http' | 'apiKey' | 'oauth2' | 'openIdConnect'
  scheme?: 'bearer' | 'basic'
  name?: string
  in?: 'header' | 'query' | 'cookie'
}
```

The runtime places the returned token based on the scheme:

| Scheme in the spec | `Auth` object                              | Where the token goes              |
| ------------------ | ------------------------------------------ | --------------------------------- |
| `http` bearer      | `{ type: 'http', scheme: 'bearer' }`       | `Authorization: Bearer <token>`   |
| `http` basic       | `{ type: 'http', scheme: 'basic' }`        | `Authorization: Basic <token>`    |
| `apiKey` header    | `{ type: 'apiKey', name, in: 'header' }`   | request header named `name`       |
| `apiKey` query     | `{ type: 'apiKey', name, in: 'query' }`    | query parameter named `name`      |
| `apiKey` cookie    | `{ type: 'apiKey', name, in: 'cookie' }`   | `Cookie` header                   |
| `oauth2`           | `{ type: 'oauth2' }`                       | `Authorization: Bearer <token>`   |
| `openIdConnect`    | `{ type: 'openIdConnect' }`                | `Authorization: Bearer <token>`   |

> [!NOTE]
> For basic auth, return the raw `username:password` string. The runtime base64-encodes it and writes the `Basic` prefix, so you never build the header yourself.

A spec that mixes schemes resolves through the same function. Branch on the `Auth` object to return the right credential:

```typescript
client.setConfig({
  auth: (auth) => {
    if (auth.type === 'apiKey') return apiKey
    return accessToken
  },
})
```

## Per-instance and per-call

`createClient` builds an isolated instance with its own `auth`, which suits multi-tenant apps where each tenant carries a different token:

```typescript
import { createClient } from './gen/clients/.kubb/client'

const tenant = createClient({
  baseURL: tenant.apiUrl,
  auth: () => tenant.token,
})

const { data } = await getPetById({ path: { petId: 1 }, client: tenant })
```

A per-call `auth` overrides the client config for a single request, which is useful for a one-off token refresh:

```typescript
const { data } = await addPet({ body: { name: 'Odie' }, auth: () => freshToken })
```

Explicit `headers` you pass on a call still win over the resolved value, so you can always set the header yourself when you need to.

## Beyond the scheme mapping

The mapping covers the schemes OpenAPI can express. For anything outside it, such as signing a request or refreshing a token on a `401`, use a request interceptor on the client. The interceptor sees the final request before it is sent, so it can add or rewrite any header the scheme mapping does not reach.

## See also

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
- [OpenAPI security scheme object](https://spec.openapis.org/oas/v3.1.0#security-scheme-object)
