---
layout: doc
title: Generate with Vite
description: Run Kubb code generation during Vite builds.
outline: [2, 3]
order: 4
navigation:
  title: Vite
  icon: i-simple-icons-vite
---

# Generate with Vite

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

> [!IMPORTANT]
> This integration generates during builds only. Run `kubb generate` before starting the development server.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [vite.config.ts]
import kubb from 'kubb/vite'
import { defineConfig } from 'vite'
import config from './kubb.config'

export default defineConfig({
  plugins: [kubb({ config })],
})
```

Run your project's Vite build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
