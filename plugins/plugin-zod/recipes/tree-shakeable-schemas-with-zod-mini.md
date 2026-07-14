---
layout: doc
title: Tree-shakeable schemas with Zod Mini
description: Generate Zod Mini schemas on the functional API so bundlers tree-shake the validators you never call.
outline: deep
---

# Tree-shakeable schemas with Zod Mini

Set [`mini`](/plugins/plugin-zod/reference/options#mini) to `true` to generate Zod Mini schemas that use the functional API, so bundlers tree-shake the validators you never call. This also defaults the import to `'zod/mini'`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      mini: true,
    }),
  ],
})
```
