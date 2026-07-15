---
layout: doc
title: Point at an env-driven host
description: Read the API host from an environment variable at runtime by setting baseURL with @kubb/plugin-fetch.
outline: deep
---

# Point at an env-driven host

Set [`baseURL`](/plugins/plugin-fetch/reference/options#baseurl) to a value with a `${...}` interpolation, which Kubb emits as a template literal in the generated client config so it reads the environment variable at runtime.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFetch({
      baseURL: '${process.env.API_URL}',
    }),
  ],
})
```

## Output example

The literal template string above is what Kubb writes into the client's setup call, so `process.env.API_URL` is read at runtime rather than substituted at build time:

```typescript twoslash [usage.ts]
import { getPetById } from './src/gen/clients/getPetById'

const { data } = await getPetById({ path: { petId: 1 } })
```
