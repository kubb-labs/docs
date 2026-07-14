---
layout: doc
title: One wildcard barrel
description: Set the barrel type to all so each barrel uses export star, a smaller barrel that re-exports everything.
outline: deep
---

# One wildcard barrel

Set [`type`](/plugins/plugin-barrel/reference/options#type) to `'all'` so each barrel uses `export *`, a smaller barrel that re-exports everything.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true, barrel: { type: 'all' } },
  plugins: [pluginTs()],
})
```
