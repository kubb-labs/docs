---
layout: doc
title: Generate with Astro
description: Run Kubb code generation during Astro builds.
outline: [2, 3]
order: 12
navigation:
  title: Astro
  icon: i-simple-icons-astro
---

# Generate with Astro

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

> [!IMPORTANT]
> This integration generates during builds only. Run `kubb generate` before starting the development server.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [astro.config.mjs]
import { defineConfig } from 'astro/config'
import kubb from 'kubb/astro'
import config from './kubb.config'

export default defineConfig({
  integrations: [kubb({ config })],
})
```

Run your project's Astro build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
