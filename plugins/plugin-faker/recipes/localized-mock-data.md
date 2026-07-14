---
layout: doc
title: Localized mock data
description: Generate region-specific mock values from @kubb/plugin-faker by setting the locale option.
outline: deep
---

# Localized mock data

Generate values that read as German by setting [`locale`](/plugins/plugin-faker/reference/options#locale) to `'de'`. The plugin switches the Faker import to `fakerDE`, so names, addresses, and phone numbers match that region.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFaker({
      locale: 'de',
    }),
  ],
})
```
