---
layout: doc
title: Generate with Rollup
description: Run Kubb code generation during Rollup builds.
outline: [2, 3]
order: 6
navigation:
  title: Rollup
  icon: i-simple-icons-rollupdotjs
---

# Generate with Rollup

The integration uses `unplugin-kubb`, which ships with `kubb`.

::steps{level="2"}

## Install Kubb and your output plugins

Follow the [installation guide](/docs/5.x/installation) to add Kubb and the plugins your output needs.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [rollup.config.ts]
import kubb from 'kubb/rollup'
import config from './kubb.config'

export default {
  input: 'src/index.ts',
  plugins: [kubb({ config })],
}
```

Run your project's Rollup build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

::

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
