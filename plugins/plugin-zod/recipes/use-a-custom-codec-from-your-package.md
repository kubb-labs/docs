---
layout: doc
title: Use a custom codec from your own package
description: Print a codec from your own package, such as myCodec.uint64(), and add its import to the generated file.
outline: deep
---

# Use a custom codec from your own package

To print `int64` fields as `myCodec.uint64()` from your own package, override the `bigint` printer node and call `this.import(...)` in it. The generated file gets the import, and Kubb keeps the package path as written.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { ast } from 'kubb/kit'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      printer: {
        nodes: {
          bigint() {
            this.import(ast.factory.createImport({ name: ['myCodec'], path: 'my-codec/zod' }))
            return 'myCodec.uint64()'
          },
        },
      },
    }),
  ],
})
```

## Output example

```typescript [src/gen/zod/counterSchema.ts]
import * as z from 'zod'
import { myCodec } from 'my-codec/zod'

export const counterSchema = z.object({
  total: myCodec.uint64(),
})
```

::: tip
Leave `root` unset on the import. With `root` set, Kubb rewrites the path as a relative path such as `../../../my-codec/zod`.
:::
