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

The integration uses `unplugin-kubb`, which ships with `kubb`.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

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

Run your project's esbuild build command to generate the files.

> [!NOTE]
> Bundler integrations do not run `output.postGenerate` commands. Use the CLI when you need them.

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
