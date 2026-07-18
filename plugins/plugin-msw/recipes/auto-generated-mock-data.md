---
layout: doc
title: Auto-generated mock data
description: Fill MSW handlers with generated Faker data by setting the parser option to faker alongside @kubb/plugin-faker.
outline: deep
---

# Auto-generated mock data

Fill each handler with generated data by setting [`parser`](/plugins/plugin-msw/reference/options#parser) to `'faker'`. This value comes from `@kubb/plugin-faker`, so add `pluginFaker()` to the plugins array alongside `pluginTs()`.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFaker(),
    pluginMsw({
      output: { path: 'handlers', mode: 'directory' },
      parser: 'faker',
    }),
  ],
})
```

## Output example

```typescript [src/gen/handlers/getPetByIdHandler.ts]
import type { GetPetByIdResponse } from '../types/GetPetById'
import { createGetPetByIdResponse } from '../mocks/createGetPetById'
import { http } from 'msw'

export function getPetByIdHandler(data?: GetPetByIdResponse | ((info: Parameters<Parameters<typeof http.get>[1]>[0]) => Response | Promise<Response>)) {
  return http.get('/pet/:petId\\:search', function handler(info) {
    if (typeof data === 'function') return data(info)

    return new Response(JSON.stringify(data || createGetPetByIdResponse(data)), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

```typescript [usage.ts]
import { setupServer } from 'msw/node'
import { getPetByIdHandler } from './src/gen/handlers/getPetByIdHandler'

// No `data` passed in, so the handler falls back to Faker-generated pet data.
const server = setupServer(getPetByIdHandler())
```
