---
layout: doc

title: Authentication in Kubb - resolve auth from your OpenAPI spec
description: Add authentication to the client Kubb generates. Resolve bearer, basic, and apiKey credentials from your OpenAPI security schemes with one auth callback.
outline: deep
---

# Authentication

Kubb reads the security schemes from your spec and attaches them to every generated call. You give the client one `auth` resolver, and the runtime adds the token to each request that needs it. Configure nothing and the calls stay unauthenticated, so generated code does nothing until you opt in.

The setup is the same for [`@kubb/plugin-fetch`](/plugins/plugin-fetch) and [`@kubb/plugin-axios`](/plugins/plugin-axios).

## Set the auth resolver

Every generated function already carries the operation's security, derived from the spec:

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

Give the client an `auth` resolver and every guarded call picks up the token:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  auth: () => localStorage.getItem('token') ?? undefined,
})
```

The resolver is a token string or a function that returns one, and the function can be async. Return `undefined` to skip a scheme. When an operation accepts more than one scheme, the runtime tries each in turn until one hands back a token.

## How tokens map to schemes

The resolver receives the resolved scheme, so one function can serve every operation:

```typescript
type Auth = {
  type: 'http' | 'apiKey' | 'oauth2' | 'openIdConnect'
  scheme?: 'bearer' | 'basic'
  name?: string
  in?: 'header' | 'query' | 'cookie'
}
```

Where the token lands depends on the scheme:

| Scheme in the spec | `Auth` object                            | Where the token goes            |
| ------------------ | ---------------------------------------- | ------------------------------- |
| `http` bearer      | `{ type: 'http', scheme: 'bearer' }`     | `Authorization: Bearer <token>` |
| `http` basic       | `{ type: 'http', scheme: 'basic' }`      | `Authorization: Basic <token>`  |
| `apiKey` header    | `{ type: 'apiKey', name, in: 'header' }` | request header named `name`     |
| `apiKey` query     | `{ type: 'apiKey', name, in: 'query' }`  | query parameter named `name`    |
| `apiKey` cookie    | `{ type: 'apiKey', name, in: 'cookie' }` | `Cookie` header                 |
| `oauth2`           | `{ type: 'oauth2' }`                     | `Authorization: Bearer <token>` |
| `openIdConnect`    | `{ type: 'openIdConnect' }`              | `Authorization: Bearer <token>` |

> [!NOTE]
> For basic auth, return the raw `username:password` string. The runtime base64-encodes it and writes the `Basic` prefix, so you never build the header yourself.

When a spec mixes schemes, read the `Auth` object and return the matching credential:

```typescript
client.setConfig({
  auth: (auth) => (auth.type === 'apiKey' ? apiKey : accessToken),
})
```

## A client per environment

`createClient` builds an isolated client with its own `auth`, which fits a multi-tenant app where each tenant carries a different token:

```typescript
import { createClient } from './gen/clients/.kubb/client'

const tenant = createClient({
  baseURL: 'https://tenant.example.com',
  auth: () => tenantToken,
})

const { data } = await getPetById({ path: { petId: 1 }, client: tenant })
```

Pass `auth` on a single call to override the client for that one request, handy for a one-off token refresh. An explicit `headers` value you set on a call always wins over the resolved token.

## Beyond the scheme mapping

The mapping covers what an OpenAPI security scheme can describe. To sign a request or refresh a token after a `401`, add a request interceptor on the client. The interceptor sees the final request before it goes out, so it can set any header the mapping does not reach.

## See also

- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
- [OpenAPI security scheme object](https://spec.openapis.org/oas/v3.1.0#security-scheme-object)
