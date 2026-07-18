# Authenticate your API client

To add authentication to your generated client, give the client one `auth` resolver. Kubb reads the security schemes from your spec and attaches them to every generated call, and the runtime adds the token to each request that needs it. Until you set a resolver the calls stay unauthenticated.

Follow the same steps for [`@kubb/plugin-fetch`](/plugins/plugin-fetch/) and [`@kubb/plugin-axios`](/plugins/plugin-axios/).

## Set the auth resolver

Every generated function already carries the operation's security, derived from the spec:

```typescript
export function addPet<ThrowOnError extends boolean = true>(
  options: Options<AddPetOptions, ThrowOnError>,
): Promise<RequestResult<AddPetResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'POST',
    url: '/pet',
    security: [{ type: 'oauth2' }],
    ...config,
  }) as Promise<RequestResult<AddPetResponses, ThrowOnError>>
}
```

Set the resolver on the client and every guarded call picks up the token:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  auth: () => localStorage.getItem('token') ?? undefined,
})
```

The resolver is a token string or a function that returns one, and the function can be async. Return `undefined` to skip a scheme. When an operation accepts more than one scheme, the runtime tries each in turn until one hands back a token.

## Return the right token per scheme

The resolver receives the resolved scheme, so one function can serve every operation. Read the `Auth` object it passes in to decide which credential to return:

```typescript
type Auth = {
  type: 'http' | 'apiKey' | 'oauth2' | 'openIdConnect'
  scheme?: 'bearer' | 'basic'
  name?: string
  in?: 'header' | 'query' | 'cookie'
}
```

The scheme decides where the runtime puts the token:

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

When a spec mixes schemes, branch on the `Auth` object and return the matching credential:

```typescript
client.setConfig({
  auth: (auth) => (auth.type === 'apiKey' ? apiKey : accessToken),
})
```

## Use a separate client per environment

To give each environment its own token, build an isolated client with `createClient`. This fits a multi-tenant app where each tenant carries a different token:

```typescript
import { createClient } from './gen/clients/.kubb/client'

const tenant = createClient({
  baseURL: 'https://tenant.example.com',
  auth: () => tenantToken,
})

const { data } = await getPetById({ path: { petId: 1 }, client: tenant })
```

To override the client for one request, pass `auth` on that single call, which suits a one-off token refresh. An explicit `headers` value you set on a call always wins over the resolved token.

## Use an interceptor instead

For anything an OpenAPI security scheme cannot describe, reach for a request interceptor. It runs on every call and sees the final request before it is sent, so it can set or rewrite any header without touching the spec.

```typescript
import { client } from './gen/clients/.kubb/client'

client.interceptors.request.use((request) => {
  request.headers.Authorization = `Bearer ${getToken()}`
  return request
})
```

Use an interceptor to sign a request or attach a credential the spec does not declare. To refresh a token after a `401`, read the new token from a response or error interceptor and let the request interceptor pick it up on the next call. For a standard bearer, basic, or apiKey scheme, the `auth` resolver stays the simpler path. The [interceptors guide](/plugins/plugin-fetch/guide/interceptors) covers the response and error channels and the full handler lifecycle.

## See also

- [Interceptors](/plugins/plugin-fetch/guide/interceptors)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
- [OpenAPI security scheme object](https://spec.openapis.org/oas/v3.1.0#security-scheme-object)
