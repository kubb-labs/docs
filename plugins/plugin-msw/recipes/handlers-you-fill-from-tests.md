---
layout: doc
title: Handlers you fill from tests
description: Generate MSW handlers that return an empty typed payload you supply from each test by keeping the parser option on its default.
outline: deep
---

# Handlers you fill from tests

Return an empty typed payload from each handler by keeping [`parser`](/plugins/plugin-msw/reference/options#parser) on its default `'data'`. Each test supplies the response body it needs, and the type comes from `@kubb/plugin-ts`.

```typescript twoslash [kubb.config.ts]
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
