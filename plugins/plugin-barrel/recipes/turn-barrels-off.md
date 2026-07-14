---
layout: doc
title: Turn barrels off
description: Set output.barrel to false so no root index.ts is written and every plugin without its own output.barrel inherits the false.
outline: deep
---

# Turn barrels off

Set [`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel) to `false` so no root `index.ts` is written and every plugin without its own `output.barrel` inherits the `false`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true, barrel: false },
  plugins: [pluginTs()],
})
```
