---
layout: doc
title: Class-based SDK
description: Generate a class-based SDK from your OpenAPI spec with @kubb/plugin-axios, one class per tag or a single flat class.
outline: deep
---

# Class-based SDK

Set [`sdk`](/plugins/plugin-axios/reference/options#sdk) to emit a class-based client, one class per tag with `mode: 'tag'` or a single flat class with `mode: 'flat'`.

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
      sdk: { mode: 'tag' },
    }),
  ],
})
```
