---
layout: doc
title: Map spec types to native TS
description: Replace a schema type handler to build your own TypeScript AST node for it.
outline: deep
---

# Map spec types to native TS

Use [`printer.nodes`](/plugins/plugin-ts/reference/options#printer) to replace the handler for a schema type with one that builds its own TypeScript AST node. This config maps the `date` type to a `Date` type reference and `integer` to the `bigint` keyword.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import ts from 'typescript'
import { pluginTs } from '@kubb/plugin-ts'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginTs({
      printer: {
        nodes: {
          date() {
            return ts.factory.createTypeReferenceNode('Date', [])
          },
          integer() {
            return ts.factory.createKeywordTypeNode(ts.SyntaxKind.BigIntKeyword)
          },
        },
      },
    }),
  ],
})
```
