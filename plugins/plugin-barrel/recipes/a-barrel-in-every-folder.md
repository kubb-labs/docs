---
layout: doc
title: A barrel in every folder
description: Set nested to true on a plugin's output.barrel so it writes an index.ts in every subdirectory, letting callers import from any depth.
outline: deep
---

# A barrel in every folder

Set [`nested`](/plugins/plugin-barrel/reference/options#nested) to `true` on a plugin's `output.barrel` so it writes an `index.ts` in every subdirectory, letting callers import from any depth. This field works on a plugin's `output.barrel` only, not on the root one.

A per-plugin barrel needs `output.mode: 'directory'`, since a plugin writing everything to a single file has no directories to walk.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [pluginTs({ output: { path: 'types', mode: 'directory', barrel: { type: 'named', nested: true } } })],
})
```
