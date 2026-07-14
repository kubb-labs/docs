---
layout: doc
title: Named re-exports for tree-shaking
description: Set the barrel type to named so each barrel re-exports symbols by name, keeping imports explicit and bundlers able to tree-shake.
outline: deep
---

# Named re-exports for tree-shaking

Set [`type`](/plugins/plugin-barrel/reference/options#type) to `'named'` so each barrel re-exports symbols by name, which keeps imports explicit and bundlers able to tree-shake.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true, barrel: { type: 'named' } },
  plugins: [pluginTs()],
})
```
