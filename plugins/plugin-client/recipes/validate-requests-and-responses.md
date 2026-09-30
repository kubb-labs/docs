---
layout: doc
title: Validate requests and responses
description: Pass Zod schemas from @kubb/plugin-zod to your client and validate bodies there.
outline: deep
---

# Validate requests and responses

`@kubb/plugin-client` does not validate on its own. With `validator` set, it passes the schemas to your client, which runs them.

::: code-group

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginClient({ importPath: '../../../client', validator: 'zod' }),
  ],
})
```

:::

Each generated call now includes the schemas:

```typescript
request({
  method: 'POST',
  url: '/pet',
  validator: { response: addPetResponseSchema, error: addPetErrorSchema },
  ...config,
})
```

Add a `validator` field to your `RequestConfig`, then run the schemas in `client`. Zod schemas follow [Standard Schema](https://standardschema.dev), so `~standard.validate` works with any compatible library:

```typescript [src/client.ts]
type Schema = { '~standard': { validate: (value: unknown) => unknown } }

export type RequestConfig = {
  // ...
  validator?: { request?: Schema; response?: Schema; error?: Schema }
}

// inside client(), after reading the body
const result = await config.validator?.response?.['~standard'].validate(body)
```

Set `validator: { request: 'zod' }` or `{ response: 'zod' }` to pass one direction only. Without `pluginZod()` in the plugins list, generation stops with an error.
