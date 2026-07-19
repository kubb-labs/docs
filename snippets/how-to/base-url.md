# Set your own baseURL

The generated client prepends a `baseURL` to every request, so it needs to know which host to call. Set your own when the spec carries no usable server URL, when you target a different host per environment (local, staging, production), or when the host depends on the running app, such as the tenant the user signed in as.

Set it at build time by reading it from the spec's servers list or passing `baseURL` to the client plugin, which bakes it into the generated code, or set it at runtime on the generated client for a value the app only knows once it runs, such as an environment variable or the signed-in tenant.

## Read it from the spec

Kubb never sets the generated client's `baseURL` for you. Setting `adapter: adapterOas({ server: { index: 0 } })` only resolves a server URL onto the document's metadata (`meta.baseURL`), which a custom `banner` or `footer` function can read, but it does not reach the client. Pass [`baseURL`](#use-the-baseurl-option) to the client plugin yourself to prepend a host to every request.

::: code-group

```yaml [OpenAPI]
openapi: 3.0.3
info:
  title: Swagger Example
  description:
  license:
    name: Apache 2.0
    url: http://www.apache.org/licenses/LICENSE-2.0.html
  version: 1.0.0
servers:
  - url: http://petstore.swagger.io/api
  - url: http://localhost:3000
```

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
  },
  adapter: adapterOas({ server: { index: 0 } }), // [!code ++]
  plugins: [pluginAxios()],
})
```

:::

`defineConfig` applies `adapterOas()` for you, so you set `adapter` only to change an adapter option. Here it sets `server.index` so the adapter resolves `http://petstore.swagger.io/api` from the spec.

## Use the baseURL option

Pass `baseURL` to the client plugin.

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginAxios } from '@kubb/plugin-axios'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: {
    path: './src/gen',
  },
  plugins: [
    pluginAxios({
      baseURL: 'https://localhost:8080/api/v1', // [!code ++]
    }),
    pluginReactQuery({
      client: 'axios',
    }),
  ],
})
```

:::

A value containing a `${...}` interpolation stays dynamic. The plugin emits it as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable when the app runs instead of baking in the build-time value.

## Set it at runtime

The `baseURL` rides the same `ClientConfig` as `auth` and the [transport](/plugins/plugin-fetch/guide/transport), so you set it at runtime the same three ways.

Call `client.setConfig({ baseURL })` to point the whole app at one URL. Every generated function imports the shared `client`, so the change reaches each call at once. This fits reading the URL from an environment variable on startup:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({ baseURL: import.meta.env.VITE_API_URL })
```

Call `createClient({ baseURL })` for an isolated client with its own URL, which fits a multi-tenant app or talking to more than one backend. Pass it on the `client` option of a call, or hand it to a query plugin:

```typescript
import { createClient } from './gen/clients/.kubb/client'
import { getPetById } from './gen/clients/getPetById'

const staging = createClient({ baseURL: 'https://staging.petstore.swagger.io/v2' })

const { data } = await getPetById({ path: { petId: 1 }, client: staging })
```

Pass `baseURL` on a single call to override the client for that one request:

```typescript
import { getPetById } from './gen/clients/getPetById'

const { data } = await getPetById({ path: { petId: 1 }, baseURL: 'https://localhost:3000' })
```

A `baseURL` set on the call wins over `createClient`, which wins over `setConfig`, which wins over the build-time value.

### Rewrite the URL with an interceptor

A request interceptor sees the final request before it is sent, so it can rewrite the URL per call from logic the static options cannot express, such as routing a path to a different host:

```typescript
import { client } from './gen/clients/.kubb/client'

client.interceptors.request.use((request) => {
  const { pathname } = new URL(request.url, 'http://placeholder')
  if (pathname.startsWith('/admin')) {
    request.url = `https://admin.petstore.swagger.io${pathname}`
  }
  return request
})
```

The interceptor receives the URL already built from the resolved `baseURL`, so reach for it only when the host depends on the request. For a fixed URL, `setConfig` and `createClient` stay the simpler path.

## See also

- [Custom transport](/plugins/plugin-fetch/guide/transport)
- [Authentication](/plugins/plugin-fetch/guide/authentication)
- [Interceptors](/plugins/plugin-fetch/guide/interceptors)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
