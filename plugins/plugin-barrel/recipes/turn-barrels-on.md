---
layout: doc
title: Turn barrels on
description: output.barrel defaults to false. Set it on defineConfig to enable a root barrel and the default every plugin without its own output.barrel inherits.
outline: deep
---

# Turn barrels on

[`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel) defaults to `false`, so no barrel is generated until you set it. Set it on `defineConfig` to enable a root barrel and the default every plugin without its own `output.barrel` inherits.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true, barrel: { type: 'named' } },
  plugins: [pluginTs()],
})
```
