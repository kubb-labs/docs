---
layout: doc
title: Handlers you fill from tests
description: Generate MSW handlers that return an empty typed payload you supply from each test by keeping the parser option on its default.
outline: deep
---

# Handlers you fill from tests

Return an empty typed payload from each handler by keeping [`parser`](/plugins/plugin-msw/reference/options#parser) on its default `'data'`. Each test supplies the response body it needs, and the type comes from `@kubb/plugin-ts`.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginMsw({
      parser: 'data',
    }),
  ],
})
```

## Output example

```typescript [src/gen/handlers/getPetByIdHandler.ts]
import type { GetPetByIdResponse } from '../types/GetPetById'
import { http } from 'msw'

export function getPetByIdHandler(data?: GetPetByIdResponse | ((info: Parameters<Parameters<typeof http.get>[1]>[0]) => Response | Promise<Response>)) {
  return http.get(`/pet/:petId\\:search`, function handler(info) {
    if (typeof data === 'function') return data(info)

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  })
}
```

```typescript [usage.ts]
import { setupServer } from 'msw/node'
import { getPetByIdHandler } from './src/gen/handlers/getPetByIdHandler'

// Each test supplies its own payload for the typed response.
const server = setupServer(getPetByIdHandler({ id: 1, name: 'Rex' }))
```
