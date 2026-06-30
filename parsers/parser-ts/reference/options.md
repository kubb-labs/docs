---
layout: doc
title: Options
description: Configuration reference for @kubb/parser-ts.
outline: deep
---

# Options

`@kubb/parser-ts` takes no options of its own. You add it to the `parsers` list as-is. To change the extension written into generated imports, set `output.extension` on `defineConfig`. The parser reads that map and rewrites each import path.

For example, `output.extension: { '.ts': '.js' }` turns `import { Pet } from './Pet'` into `import { Pet } from './Pet.js'`. Node's ESM resolver expects that `.js` suffix.

::: code-group

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { parserTs } from '@kubb/parser-ts'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen', extension: { '.ts': '.js' } },
  adapter: adapterOas(),
  parsers: [parserTs],
  plugins: [],
})
```

```typescript [Generated import]
import type { Pet } from './Pet.js'
```

:::
