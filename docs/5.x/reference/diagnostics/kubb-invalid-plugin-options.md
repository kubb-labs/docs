---
layout: doc
title: KUBB_INVALID_PLUGIN_OPTIONS
description: The KUBB_INVALID_PLUGIN_OPTIONS diagnostic fires when a plugin is configured with options that cannot be honored, such as output.mode 'file' paired with a group option.
outline: [2, 3]
---

# KUBB_INVALID_PLUGIN_OPTIONS: Invalid plugin options

Code: `KUBB_INVALID_PLUGIN_OPTIONS`
Level: error

A plugin was given options that cannot be honored together. The main case is `output.mode` resolving to `'file'` while a `group` option is also set. A single-file output has nothing to split into groups, so the build stops instead of producing a layout the options do not describe.

## What happened

`output.mode: 'file'` writes everything into one file at `output.path`. The `group` option splits output into per-tag or per-path subdirectories, which only applies to `output.mode: 'directory'`. Kubb reports the contradiction as invalid at plugin setup rather than guessing a layout.

An unset `output.mode` follows `output.path`: an extension means `'file'`, anything else `'directory'`. So this fires whenever `path` resolves to a file, whether `mode: 'file'` was set directly or `path` names a file such as `'clients.ts'`. The TypeScript types catch an explicit `mode: 'file'` paired with `group` at compile time, but the inferred case (an extension in `path`, no `mode` set) only surfaces here, along with any config written in JavaScript or cast to `any`.

## How to fix it

- Remove the `group` option when you want a single file.
- Or give `output.path` an extensionless name (the default for most plugins) so it resolves to `'directory'` and keep `group` to organize that output into subdirectories. Set `output.mode: 'directory'` explicitly only if the directory name itself carries a dot, such as `'clients.v2'`.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'
import { pluginAxios } from '@kubb/plugin-axios'

export default defineConfig({
  input: './petStore.yaml',
  output: { path: './src/gen' },
  plugins: [
    pluginAxios({
      output: { path: 'clients' },
      group: { type: 'tag' },
    }),
  ],
})
```

## Common causes

- A plugin's `output.path` names a file (an extension, or an explicit `mode: 'file'`) while a sibling `group` option is also set.
- Two plugins list each other in `dependencies`, so the graph has a cycle and the plugins cannot be ordered. The message names the cycle: `Plugin dependencies form a cycle: plugin-a → plugin-b → plugin-a.` Remove one of the `dependencies` entries to break it.

## Example output

```text [Terminal]
[KUBB_INVALID_PLUGIN_OPTIONS] plugin-axios: Plugin "plugin-axios" resolves `output.mode` to 'file' but also configures a `group` option.
  fix: A single-file output has nothing to group. Remove the `group` option, give `output.path` an extensionless directory name, or set `output.mode: 'directory'` explicitly.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-invalid-plugin-options
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
