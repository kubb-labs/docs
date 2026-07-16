---
layout: doc
title: Validate every API response
description: Point a Fetch client at the generated Zod schemas to validate every response body at runtime.
outline: deep
---

# Validate every API response

Generate the Zod schemas, then point a client at them. Setting the Fetch client's [`validator`](/plugins/plugin-fetch/reference/options#validator) to `'zod'` runs every response body through the matching schema at runtime. To validate request bodies too, use the object form `{ request: 'zod', response: 'zod' }`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginFetch({
      validator: 'zod',
    }),
  ],
})
```

## Output example

```typescript [src/gen/clients/findPetsByStatus.ts]
import type { Options, RequestResult } from '../.kubb/client'
import type { FindPetsByStatusOptions, FindPetsByStatusResponses } from '../types/FindPetsByStatus'
import { client } from '../.kubb/client'
import { findPetsByStatusResponseSchema, findPetsByStatusErrorSchema } from '../zod/findPetsByStatusSchema'

export function findPetsByStatus<ThrowOnError extends boolean = true>(options: Options<FindPetsByStatusOptions, ThrowOnError> = {}): Promise<RequestResult<FindPetsByStatusResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({ method: 'GET', url: '/pet/findByStatus', validator: { response: findPetsByStatusResponseSchema, error: findPetsByStatusErrorSchema }, ...config }) as Promise<RequestResult<FindPetsByStatusResponses, ThrowOnError>>
}
```

```typescript [usage.ts]
import { findPetsByStatus } from './src/gen/clients/findPetsByStatus'

// throws if the response body fails findPetsByStatusResponseSchema.parse(...)
const { data } = await findPetsByStatus({ query: { status: ['available'] } })
```

