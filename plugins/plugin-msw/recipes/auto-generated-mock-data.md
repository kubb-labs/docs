---
layout: doc
title: Auto-generated mock data
description: Fill MSW handlers with generated Faker data by setting the parser option to faker alongside @kubb/plugin-faker.
outline: deep
---

# Auto-generated mock data

Fill each handler with generated data by setting [`parser`](/plugins/plugin-msw/reference/options#parser) to `'faker'`. This value comes from `@kubb/plugin-faker`, so add `pluginFaker()` to the plugins array alongside `pluginTs()`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFaker } from '@kubb/plugin-faker'
import { pluginMsw } from '@kubb/plugin-msw'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFaker(),
    pluginMsw({
      parser: 'faker',
    }),
  ],
})
```
