---
layout: doc
title: Turn barrels off
description: output.barrel already defaults to false. Set it explicitly to override a barrel enabled elsewhere, like a shared base config.
outline: deep
---

# Turn barrels off

[`output.barrel`](/plugins/plugin-barrel/reference/options#output-barrel) already defaults to `false`, so a fresh config needs nothing here. Set it explicitly to override a root barrel enabled elsewhere, for example a shared base config: no root `index.ts` is written, and every plugin without its own `output.barrel` inherits the `false`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true, barrel: false },
  plugins: [pluginTs()],
})
```
