# Authenticate your API client

Set an `auth` resolver on the generated Fetch or Axios client. Operations use the security schemes declared in your OpenAPI spec. Requests remain unauthenticated until you provide credentials.

## Set the auth resolver

Set the resolver for all secured operations:

```typescript
import { client } from './gen/.kubb/client'

client.setConfig({
  auth: () => localStorage.getItem('token') ?? undefined,
})
```

The resolver is a token string, or a function (which can be async) that returns one or `undefined` to skip a scheme. When an operation accepts more than one scheme, the runtime tries each in turn until one hands back a token.

## Return the right token per scheme

Use the scheme passed to the resolver to select a credential:

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

To give each environment its own token, such as one per tenant in a multi-tenant app, build an isolated client with `createClient`:

```typescript
import { createClient } from './gen/.kubb/client'

const tenant = createClient({
  baseURL: 'https://tenant.example.com',
  auth: () => tenantToken,
})

const { data } = await getPetById({ path: { petId: 1 }, client: tenant })
```

To override the client for one request, pass `auth` on that single call, which suits a one-off token refresh. An explicit `headers` value you set on a call always wins over the resolved token.

For authentication outside OpenAPI security schemes, use an async [request interceptor](/plugins/plugin-fetch/guide/interceptors) to sign requests or supply custom headers.

## See also

- [Interceptors](/plugins/plugin-fetch/guide/interceptors)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
- [OpenAPI security scheme object](https://spec.openapis.org/oas/v3.1.0#security-scheme-object)
