---
layout: doc
title: KUBB_PLUGIN_NOT_FOUND
description: The KUBB_PLUGIN_NOT_FOUND diagnostic, raised when a plugin another plugin depends on is missing from your kubb.config.ts.
outline: [2, 3]
---

# KUBB_PLUGIN_NOT_FOUND: Plugin not found

Code: `KUBB_PLUGIN_NOT_FOUND`
Level: error

A plugin requires another plugin that is not in the config.

## What happened

Some plugins build on others. The query and client generators, for example, need `@kubb/plugin-ts` for the types they emit. When a plugin declares a dependency that is not registered, Kubb cannot run it. OpenAPI parsing is no longer a plugin dependency in v5. The `adapter` reads the document, so you never list `@kubb/plugin-oas`.

## How to fix it

- Add the required plugin to the `plugins` array, and install it if needed.
- Order does not matter. Kubb sorts plugins so dependencies run first. Just make sure the plugin is present.
- Remove the plugin that depends on it if you do not need it.

## Common causes

- The required plugin is installed but not added to the `plugins` array.
- The required plugin is missing from `package.json` entirely.

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb'
import { pluginReactQuery } from '@kubb/plugin-react-query'
// @kubb/plugin-ts is missing, but pluginReactQuery needs it for the generated types

export default defineConfig({
  input: { path: './petstore.yaml' },
  output: { path: './src/gen' },
  plugins: [pluginReactQuery()],
})
```

## Example output

```txt
[KUBB_PLUGIN_NOT_FOUND]: Plugin "@kubb/plugin-ts" is required but not found. Make sure it is included in your Kubb config.
  fix: Add "@kubb/plugin-ts" to the plugins array in kubb.config.ts, or remove the dependency on it.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-plugin-not-found
```

## See also

- [Configuration reference](/docs/5.x/reference/configuration)
- [Plugins concept](/docs/5.x/concepts/plugins)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
