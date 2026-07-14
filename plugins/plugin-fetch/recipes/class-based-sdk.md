---
layout: doc
title: Class-based SDK
description: Generate a class-based SDK from your OpenAPI spec with @kubb/plugin-fetch, one class per tag or a single flat class.
outline: deep
---

# Class-based SDK

Set [`sdk`](/plugins/plugin-fetch/reference/options#sdk) to emit a class-based client, one class per tag with `mode: 'tag'` or a single flat class with `mode: 'flat'`.

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
      sdk: { mode: 'tag' },
    }),
  ],
})
```
