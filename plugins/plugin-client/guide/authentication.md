---
layout: doc
title: Authenticate
description: Use the security list that @kubb/plugin-client passes to your client to add tokens, signing, or any other auth, including credentials fetched asynchronously.
outline: deep
---

# Authenticate

Auth lives in your `client`. The plugin does not send credentials itself. It tells your client which schemes each operation needs, and your client decides what to do.

## The `security` list

Each generated function passes the operation's security schemes from the spec as `security`:

```typescript
request({
  method: 'GET',
  url: '/pet/{petId}',
  security: [{ type: 'apiKey', name: 'api_key', in: 'header' }, { type: 'oauth2' }],
  ...config,
})
```

An operation without security requirements passes no `security` field. Use that to skip auth on public endpoints.

## Add a bearer token from an async source

The client can `await` anything before it sends the request. This one asks a registered function for a token, so the token can come from a secrets store or a refresh call:

```typescript [src/client.ts]
type GetToken = () => Promise<string | undefined>

let getToken: GetToken | undefined

export function setAuth(resolve: GetToken) {
  getToken = resolve
}

export async function client(config: RequestConfig) {
  const token = config.security?.length ? await getToken?.() : undefined

  const response = await fetch(url, {
    method: config.method,
    headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(config.headers as Record<string, string>) },
    // ...
  })
  // ...
}
```

```typescript [src/index.ts]
import { setAuth } from './client'

setAuth(async () => readTokenFromSecretsStore())
```

## Sign requests or use several auth methods

Read `config.security` and pick per operation, or pass a different `client` on a call. This works for request signing, such as AWS SigV4, and for services that use different credentials:

```typescript
import { createSignedClient } from './clients/iam'

await getPetById({ path: { petId: 1 }, client: createSignedClient() })
```

A client passed on a call replaces the default for that call only.
