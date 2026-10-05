---
layout: doc
title: Generate with Rolldown
description: Run Kubb code generation during Rolldown builds.
outline: [2, 3]
order: 7
navigation:
  title: Rolldown
  icon: i-simple-icons-rolldown
---

# Generate with Rolldown

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [rolldown.config.ts]
import kubb from 'kubb/rolldown'
import { defineConfig } from 'rolldown'
import config from './kubb.config'

export default defineConfig({
  input: 'src/index.ts',
  plugins: [kubb({ config })],
})
```

Run your project's Rolldown build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
