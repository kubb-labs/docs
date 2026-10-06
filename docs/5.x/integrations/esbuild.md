---
layout: doc
title: Generate with esbuild
description: Run Kubb code generation during esbuild builds.
outline: [2, 3]
order: 9
navigation:
  title: esbuild
  icon: i-simple-icons-esbuild
---

# Generate with esbuild

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [build.ts]
import { build } from 'esbuild'
import kubb from 'kubb/esbuild'
import config from './kubb.config'

await build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/bundle.js',
  plugins: [kubb({ config })],
})
```

Run your project's esbuild build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
