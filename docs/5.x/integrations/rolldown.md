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

The integration uses `unplugin-kubb`, which ships with `kubb`.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

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

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
