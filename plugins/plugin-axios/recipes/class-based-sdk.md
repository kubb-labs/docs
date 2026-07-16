---
layout: doc
title: Class-based SDK
description: Generate a class-based SDK from your OpenAPI spec with @kubb/plugin-axios, one class per tag or a single flat class.
outline: deep
---

# Class-based SDK

Set [`sdk`](/plugins/plugin-axios/reference/options#sdk) to emit a class-based client, one class per tag with `mode: 'tag'` or a single flat class with `mode: 'flat'`.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginAxios({
      sdk: { mode: 'tag' },
    }),
  ],
})
```

## Output example

```typescript [src/gen/clients/petClient.ts]
import type { ClientConfig, ClientInstance, Options, RequestResult } from '../.kubb/client'
import type { GetPetByIdOptions, GetPetByIdResponses } from '../types/GetPetById'
import { createClient } from '../.kubb/client'

export class PetClient {
  private readonly client: ClientInstance

  constructor(config: ClientConfig = {}) {
    this.client = createClient(config)
  }

  public getPetById<ThrowOnError extends boolean = true>(options: Options<GetPetByIdOptions, ThrowOnError>): Promise<RequestResult<GetPetByIdResponses, ThrowOnError>> {
    const { client: request = this.client, ...config } = options

    return request({ method: 'GET', url: '/pet/{petId}', ...config }) as Promise<RequestResult<GetPetByIdResponses, ThrowOnError>>
  }
}
```

```typescript [usage.ts]
import { PetClient } from './src/gen/clients/petClient'

const pet = new PetClient({ baseURL: 'https://petstore.swagger.io/v2' })
const { data } = await pet.getPetById({ path: { petId: 1 } })
```
