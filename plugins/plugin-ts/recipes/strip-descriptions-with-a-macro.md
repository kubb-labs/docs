---
layout: doc
title: Strip descriptions with a macro
description: Register a macro through the macros option to drop every schema description before plugin-ts prints its JSDoc.
outline: deep
---

# Strip descriptions with a macro

Pass a [macro](/plugins/plugin-ts/reference/options#macros) that clears `description` on every schema node. Macros run on the shared AST before a plugin prints code, so this keeps the generated types free of the spec's prose without touching the OpenAPI document.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginTs } from '@kubb/plugin-ts'
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
    pluginTs({
      output: { path: 'types', mode: 'directory' },
      macros: [macroDropDescriptions],
    }),
  ],
})
```

## Output example

```typescript [src/gen/types/Pet.ts]
export type Pet = {
    /**
     * @type string | undefined
    */
    status?: PetStatusEnumKey;
};
```

Without the macro, that same property also carries the spec's prose: `/** @description pet status in the store */`.
