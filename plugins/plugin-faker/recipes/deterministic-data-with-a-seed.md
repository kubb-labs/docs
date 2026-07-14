---
layout: doc
title: Deterministic data with a seed
description: Produce the same mock values on every run by setting the seed option in @kubb/plugin-faker.
outline: deep
---

# Deterministic data with a seed

Set [`seed`](/plugins/plugin-faker/reference/options#seed) so the factories call `faker.seed(...)` and return the same values on every run. This keeps snapshot tests stable and makes a failing case reproducible.

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
      seed: [100],
    }),
  ],
})
```
