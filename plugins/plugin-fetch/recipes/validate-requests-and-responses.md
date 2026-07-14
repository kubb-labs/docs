---
layout: doc
title: Validate requests and responses
description: Validate request and response bodies at runtime with Zod schemas using @kubb/plugin-fetch and @kubb/plugin-zod.
outline: deep
---

# Validate requests and responses

Set [`validator`](/plugins/plugin-fetch/reference/options#validator) to `{ request: 'zod', response: 'zod' }` so the client checks both request and response bodies against the generated schemas at runtime, and add `@kubb/plugin-zod` to the plugins list. The `'zod'` shorthand covers responses only, so name both directions to validate requests too.

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
      validator: { request: 'zod', response: 'zod' },
    }),
  ],
})
```
