---
layout: doc
title: Generate with Nuxt
description: Run Kubb code generation during Nuxt builds.
outline: [2, 3]
order: 11
navigation:
  title: Nuxt
  icon: i-simple-icons-nuxt
---

# Generate with Nuxt

The integration uses `unplugin-kubb`, which ships with `kubb`.

> [!IMPORTANT]
> This integration generates during builds only. Run `kubb generate` before starting the development server.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [nuxt.config.ts]
import config from './kubb.config'

export default defineNuxtConfig({
  modules: [['kubb/nuxt', { config }]],
})
```

Run your project's Nuxt build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
