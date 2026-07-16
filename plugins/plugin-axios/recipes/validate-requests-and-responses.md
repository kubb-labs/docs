---
layout: doc
title: Validate requests and responses
description: Validate request and response bodies at runtime with Zod schemas using @kubb/plugin-axios and @kubb/plugin-zod.
outline: deep
---

# Validate requests and responses

Set [`validator`](/plugins/plugin-axios/reference/options#validator) to `{ request: 'zod', response: 'zod' }` so the client checks both request and response bodies against the generated schemas at runtime, and add `@kubb/plugin-zod` to the plugins list. The `'zod'` shorthand covers responses only, so name both directions to validate requests too.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginZod } from '@kubb/plugin-zod'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginZod(),
    pluginAxios({
      validator: { request: 'zod', response: 'zod' },
    }),
  ],
})
```

## Output example

```typescript [src/gen/clients/addPet.ts]
import type { Options, RequestResult } from '../.kubb/client'
import type { AddPetOptions, AddPetResponses } from '../types/AddPet'
import { client } from '../.kubb/client'
import { addPetResponseSchema, addPetErrorSchema, addPetBodySchema } from '../zod/addPetSchema'

export function addPet<ThrowOnError extends boolean = true>(options: Options<AddPetOptions, ThrowOnError>): Promise<RequestResult<AddPetResponses, ThrowOnError>> {
  const { client: request = client, ...config } = options

  return request({
    method: 'POST',
    url: '/pet',
    validator: { request: addPetBodySchema, response: addPetResponseSchema, error: addPetErrorSchema },
    ...config,
  }) as Promise<RequestResult<AddPetResponses, ThrowOnError>>
}
```

```typescript [usage.ts]
import { addPet } from './src/gen/clients/addPet'

try {
  // body is checked against addPetBodySchema before the request is sent
  const { data } = await addPet({ body: { name: 'Rex', photoUrls: [] } })
} catch (error) {
  // ParseError when request or response fails schema validation
  console.error(error)
}
```
