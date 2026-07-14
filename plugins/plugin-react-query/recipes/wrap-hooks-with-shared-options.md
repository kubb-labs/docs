---
layout: doc
title: Wrap every hook with shared options
description: Route every generated hook through your own options function with @kubb/plugin-react-query's customOptions.
outline: deep
---

# Wrap every hook with shared options

Set [`customOptions`](/plugins/plugin-react-query/reference/options#customoptions) to route every generated hook through your own function, so shared behavior like `onSuccess` or `select` stays in one place instead of repeated per call. The plugin also emits a `HookOptions` type so your wrapper stays in sync with the generated hooks.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginFetch } from '@kubb/plugin-fetch'
import { pluginReactQuery } from '@kubb/plugin-react-query'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs(),
    pluginFetch(),
    pluginReactQuery({
      hooks: true,
      customOptions: {
        importPath: './useCustomHookOptions',
        name: 'useCustomHookOptions',
      },
    }),
  ],
})
```
