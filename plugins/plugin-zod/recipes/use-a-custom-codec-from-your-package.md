---
layout: doc
title: Use a custom codec from your own package
description: Print a codec from your own package, such as myCodec.uint64(), and add its import only to the files that use it.
outline: deep
---

# Use a custom codec from your own package

Say your package `my-codec/zod` exports a `myCodec` object with Zod codecs, and you want `int64` fields to print as `myCodec.uint64()`. The [printer](/plugins/plugin-zod/reference/options#printer) handler emits the call. Every file that contains the call also needs `import { myCodec } from 'my-codec/zod'`.

Pick one of two ways to add the import. Both keep the package specifier as written and leave the import out of files that never use `myCodec`.

## Declare the import in the handler

Call `this.import(...)` next to the code the handler prints. The import travels with the code, so it can't drift from it.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { ast } from 'kubb/kit'
import { pluginZod } from '@kubb/plugin-zod'

const myCodec = ast.factory.createImport({ name: ['myCodec'], path: 'my-codec/zod' })

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: { path: 'zod', mode: 'directory' },
      printer: {
        nodes: {
          bigint() {
            this.import(myCodec)
            return 'myCodec.uint64()'
          },
        },
      },
    }),
  ],
})
```

The handler can also wrap the built-in output. Call `this.base(node)` inside `overrides` to reuse it.

## Declare the import in the output options

Use [`output.imports`](/docs/5.x/reference/configuration#output-imports) when the import belongs to the whole plugin, or when several handlers use the same package.

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { ast } from 'kubb/kit'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen', clean: true },
  plugins: [
    pluginZod({
      output: {
        path: 'zod',
        mode: 'directory',
        imports: [ast.factory.createImport({ name: ['myCodec'], path: 'my-codec/zod' })],
      },
      printer: {
        nodes: {
          bigint() {
            return 'myCodec.uint64()'
          },
        },
      },
    }),
  ],
})
```

## Output example

A schema with an `int64` field gets the import.

```typescript [src/gen/zod/counterSchema.ts]
import * as z from 'zod'
import { myCodec } from 'my-codec/zod'

export const counterSchema = z.object({
  total: myCodec.uint64(),
})
```

A schema with no `int64` field does not.

```typescript [src/gen/zod/petNameSchema.ts]
import * as z from 'zod'

export const petNameSchema = z.string()
```

::: tip
Leave `root` unset on the import. Kubb then keeps `my-codec/zod` as written. With `root` set, Kubb rewrites the path as a relative path such as `../../../my-codec/zod`.
:::
