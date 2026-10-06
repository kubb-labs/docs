---
layout: doc
title: Generate with Farm
description: Run Kubb code generation during Farm builds.
outline: [2, 3]
order: 10
navigation:
  title: Farm
  icon: i-iconoir-light-bulb
---

# Generate with Farm

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [farm.config.ts]
import { defineConfig } from '@farmfe/core'
import kubb from 'kubb/farm'
import config from './kubb.config'

export default defineConfig({
  plugins: [kubb({ config })],
})
```

Run your project's Farm build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
