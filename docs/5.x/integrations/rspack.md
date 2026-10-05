---
layout: doc
title: Generate with Rspack
description: Run Kubb code generation during Rspack builds.
outline: [2, 3]
order: 8
navigation:
  title: Rspack
  icon: i-iconoir-journal
---

# Generate with Rspack

Install [Kubb and your output plugins](/docs/5.x/installation), then create a [Kubb config](/docs/5.x/reference/configuration). The integration uses `unplugin-kubb`, included with `kubb`.

## Configure the integration

Import your shared `kubb.config.ts` and pass it to the integration:

```typescript [rspack.config.ts]
import kubb from 'kubb/rspack'
import config from './kubb.config'

export default {
  plugins: [kubb({ config })],
}
```

Run your project's Rspack build command to generate the files. Bundler integrations do not run `output.postGenerate` commands; use the CLI when you need them.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Other build tools](/docs/5.x/integrations/build-tools)
