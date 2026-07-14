---
layout: doc
title: Tree-shakeable enums
description: Emit each OpenAPI enum as an as const object so bundlers drop the values you never use.
outline: deep
---

# Tree-shakeable enums

Set [`enum.type`](/plugins/plugin-ts/reference/options#enum-type) to `'asConst'` to emit each enum as an `as const` object plus a companion key type. The object carries no runtime beyond its values, so bundlers drop what you do not use. Switch the value to `'enum'`, `'literal'`, or `'inlineLiteral'` for the other shapes.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      enum: { type: 'asConst' },
    }),
  ],
})
```
