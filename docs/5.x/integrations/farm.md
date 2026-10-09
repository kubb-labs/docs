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

The integration uses `unplugin-kubb`, which ships with `kubb`.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

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

Run your project's Farm build command to generate the files.

> [!NOTE]
> Bundler integrations do not run `output.postGenerate` commands. Use the CLI when you need them.

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
