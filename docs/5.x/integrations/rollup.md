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

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

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

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
