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

The integration uses `unplugin-kubb`, which ships with `kubb`.

> [!IMPORTANT]
> This integration generates during builds only. Run `kubb generate` before starting the development server.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

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

Run your project's Vite build command to generate the files.

> [!NOTE]
> Bundler integrations do not run `output.postGenerate` commands. Use the CLI when you need them.

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
