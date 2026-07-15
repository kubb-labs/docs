---
layout: doc
title: Point at an env-driven host
description: Read the API host from an environment variable at runtime by setting baseURL with @kubb/plugin-axios.
outline: deep
---

# Point at an env-driven host

Set [`baseURL`](/plugins/plugin-axios/reference/options#baseurl) to a value with a `${...}` interpolation, which Kubb emits as a template literal in the generated client config so it reads the environment variable at runtime.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginAxios({
      baseURL: '${process.env.API_URL}',
    }),
  ],
})
```

## Output example

The literal template string above is what Kubb writes into the client's setup call, so `process.env.API_URL` is read at runtime rather than substituted at build time:

```typescript twoslash [usage.ts]
process.env.API_URL = 'https://petstore.swagger.io/v2'

import { getPetById } from './src/gen/clients/getPetById'

const { data } = await getPetById({ path: { petId: 1 } })
```
