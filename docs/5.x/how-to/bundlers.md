---
layout: doc
title: Integrate a bundler
description: Generate code during builds with Vite, Rollup, Rolldown, webpack,
  Rspack, esbuild, Farm, Nuxt, or Astro.
outline:
  - 2
  - 3
order: 6
navigation:
  title: Integrate a bundler
---

# Integrate a bundler

Kubb's bundler entrypoints run generation during your build. Install `kubb` and your selected output plugins, then create a [Kubb config](/docs/5.x/reference/configuration).

The entrypoints use `unplugin-kubb`, included with `kubb`. Pass a `UserConfig` to the `config` option.

> [!IMPORTANT]
> Vite, Nuxt, and Astro generate during builds only. Run `kubb generate` before starting their dev servers.

> [!NOTE]
> Bundler integrations do not run `output.postGenerate` commands. Use the CLI when you need them.

## Configure your build

Choose your build tool. Each example imports the shared `kubb.config.ts`:

::code-group

```typescript [vite.config.ts]
import kubb from 'kubb/vite'
import { defineConfig } from 'vite'
import config from './kubb.config'

export default defineConfig({
  plugins: [kubb({ config })],
})
```

```typescript [rollup.config.ts]
import kubb from 'kubb/rollup'
import config from './kubb.config'

export default {
  input: 'src/index.ts',
  plugins: [kubb({ config })],
}
```

```typescript [rolldown.config.ts]
import kubb from 'kubb/rolldown'
import { defineConfig } from 'rolldown'
import config from './kubb.config'

export default defineConfig({
  input: 'src/index.ts',
  plugins: [kubb({ config })],
})
```

```typescript [webpack.config.ts]
import kubb from 'kubb/webpack'
import config from './kubb.config'

export default {
  plugins: [kubb({ config })],
}
```

```typescript [rspack.config.ts]
import kubb from 'kubb/rspack'
import config from './kubb.config'

export default {
  plugins: [kubb({ config })],
}
```

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

```typescript [farm.config.ts]
import { defineConfig } from '@farmfe/core'
import kubb from 'kubb/farm'
import config from './kubb.config'

export default defineConfig({
  plugins: [kubb({ config })],
})
```

```typescript [nuxt.config.ts]
import config from './kubb.config'

export default defineNuxtConfig({
  modules: [['kubb/nuxt', { config }]],
})
```

```typescript [astro.config.mjs]
import { defineConfig } from 'astro/config'
import kubb from 'kubb/astro'
import config from './kubb.config'

export default defineConfig({
  integrations: [kubb({ config })],
})
```

::

## See also

- [Quickstart](/docs/5.x/tutorials/quickstart)
- [Configuration](/docs/5.x/reference/configuration)
- [Generate command](/docs/5.x/reference/commands/generate)
