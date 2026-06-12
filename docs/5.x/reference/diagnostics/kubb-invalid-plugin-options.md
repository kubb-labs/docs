---
layout: doc
title: KUBB_INVALID_PLUGIN_OPTIONS
description: The KUBB_INVALID_PLUGIN_OPTIONS diagnostic fires when a plugin is configured with options that cannot be honored, such as output.mode 'file' paired with a group option.
outline: [2, 3]
---

# KUBB_INVALID_PLUGIN_OPTIONS

**Severity:** error · **Source:** Configuration

A plugin was given options that cannot be honored together. The main case is `output.mode: 'file'`
paired with a `group` option: a single-file output has nothing to split into groups, so the build
stops instead of producing something the options do not describe.

```sh
× plugin-client(KUBB_INVALID_PLUGIN_OPTIONS): Plugin "plugin-client" sets `output.mode: 'file'` but also configures a `group` option.
  help: A single-file output has nothing to group. Remove the `group` option, or use `output.mode: 'directory'` to organize files into subdirectories.
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-invalid-plugin-options
```

## What it means

`output.mode: 'file'` writes everything into one file at `output.path`. The `group` option splits
output into per-tag or per-path subdirectories, which only applies to `output.mode: 'directory'`.
Combining the two contradicts itself, so Kubb reports the configuration as invalid at plugin setup
rather than guessing a layout. The TypeScript types catch the same mistake at compile time, but a
config written in JavaScript or cast to `any` only surfaces it here.

## Common causes

- A plugin sets `output: { mode: 'file' }` but also passes a sibling `group` option.

## How to fix

- Remove the `group` option when you want a single file.
- Or switch to `output.mode: 'directory'` (the default, one file per operation or schema) and keep
  `group` to organize that output into subdirectories.

```typescript
import { defineConfig } from 'kubb'
import { pluginClient } from '@kubb/plugin-client'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [
    pluginClient({
      output: { path: 'clients', mode: 'directory' },
      group: { type: 'tag' },
    }),
  ],
})
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
