---
layout: doc
title: KUBB_ADAPTER_REQUIRED
description: The KUBB_ADAPTER_REQUIRED diagnostic fires when an action needs an adapter but none is configured.
outline: [2, 3]
---

# KUBB_ADAPTER_REQUIRED: Adapter required

Code: `KUBB_ADAPTER_REQUIRED`
Level: error

An action needs an adapter but none is configured.

## What happened

The adapter turns your spec into the AST that plugins generate from. It has to be set before any plugin runs. This diagnostic fires when the config has no `adapter`.

## How to fix it

Set `adapter` in `kubb.config.ts`.

```typescript twoslash
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  adapter: adapterOas(),
  plugins: [/* ... */],
})
```

## Example output

```txt
[KUBB_ADAPTER_REQUIRED]: An adapter is required, but none is configured.
  fix: Set `adapter` in kubb.config.ts (for example `adapterOas()`).
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-adapter-required
```

## See also

- [Adapters](/docs/5.x/concepts/adapters)
- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
