---
layout: doc
title: Validate requests and responses
description: Pass Zod schemas from @kubb/plugin-zod to your client and validate request and response bodies there. The client runs the schemas, not Kubb.
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
type Result = { value: unknown; issues?: undefined } | { issues: ReadonlyArray<unknown> }
type Schema = { '~standard': { validate: (value: unknown) => Result | Promise<Result> } }

export type RequestConfig = {
  // ...
  validator?: { request?: Schema; response?: Schema; error?: Schema }
}

// inside client(), after reading the body
const result = await config.validator?.response?.['~standard'].validate(body)
if (result && 'issues' in result && result.issues) throw new Error('Response validation failed')
const validatedBody = result && 'value' in result ? result.value : body
```

Return `validatedBody` as `data`, so a schema that transforms the value takes effect. Without a response schema, `validatedBody` is the original `body`.

Set `validator: { request: 'zod' }` or `{ response: 'zod' }` to pass one direction only. Without `pluginZod()` in the plugins list, generation stops with an error.
