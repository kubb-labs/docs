---
layout: doc
title: Strip descriptions with a macro
description: Register a macro through the macros option to drop every schema description before plugin-zod prints a .describe() call.
outline: deep
---

# Strip descriptions with a macro

Pass a [macro](/plugins/plugin-zod/reference/options#macros) that clears `description` on every schema node. Macros run on the shared AST before a plugin prints code, so this keeps generated schemas free of the spec's prose without touching the OpenAPI document, and the same macro works for `@kubb/plugin-ts` too since both read the same AST.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginZod } from '@kubb/plugin-zod'
import { ast } from 'kubb/kit'

const macroDropDescriptions = ast.defineMacro({
  name: 'drop-descriptions',
  schema(node) {
    return 'description' in node && node.description ? { ...node, description: undefined } : undefined
  },
})

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      macros: [macroDropDescriptions],
    }),
  ],
})
```

## Output example

```typescript twoslash [src/gen/zod/petSchema.ts]
export const petSchema = z.object({
  status: z.enum(['available', 'pending', 'sold']).optional(),
})
```

Without the macro, that same field carries the spec's prose in a `.describe(...)` call: `z.enum(['available', 'pending', 'sold']).optional().describe('pet status in the store')`.
