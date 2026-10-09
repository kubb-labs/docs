# Set the base URL

Set `baseURL` on the client plugin or on the generated client.

> [!NOTE]
> OpenAPI server URLs do not configure the client automatically. The adapter's server option only sets document metadata.

## Use the baseURL option

Pass `baseURL` to the client plugin to set the generated default. `pluginAxios` takes the same option. Include `pluginTs`, which the client requires.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginFetch({ baseURL: 'https://localhost:8080/api/v1' }),
  ],
})
```

A value containing a `${...}` interpolation stays dynamic. The plugin emits it as a template literal in the generated client config, so `baseURL: '${process.env.API_URL}'` reads the environment variable when the app runs instead of baking in the build-time value.

## Set it at runtime

Use `client.setConfig` to configure all operations at startup:

```typescript
import { client } from './gen/.kubb/client'

client.setConfig({ baseURL: import.meta.env.VITE_API_URL })
```

Use `createClient` for an isolated client, then pass it to an operation:

```typescript
import { createClient } from './gen/.kubb/client'
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
