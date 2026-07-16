---
layout: doc
title: Standalone API docs page
description: Generate a single HTML file with the spec embedded inline that you can drop on any static host with no build step.
outline: deep
---

# Standalone API docs page

Generate a single HTML file with the spec embedded inline. Drop it on any static host, no build step. Point [`output.path`](/plugins/plugin-redoc/reference/options#output) at a filename ending in `.html`, resolved against the top-level `output.path`.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginRedoc } from '@kubb/plugin-redoc'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginRedoc({
      output: { path: 'docs.html' },
    }),
  ],
})
```
