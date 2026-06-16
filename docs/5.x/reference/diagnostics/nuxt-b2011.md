---
layout: doc
title: NUXT_B2011
description: The NUXT_B2011 diagnostic fires when a Nuxt plugin's filename suffix (.client / .server) conflicts with its registered mode property.
outline: [2, 3]
---

# NUXT_B2011

**Severity:** error · **Source:** Nuxt plugin resolver

A plugin's filename suffix says it should run on one side, but its `mode` property says the other.

```txt
[NUXT_B2011] Plugin `./runtime/analytics.server.ts` is server-only but was registered with mode `client`.
├▶ fix: Rename the file or register it with mode `server`.
├▶ sources: nuxt.config.ts:12:5
╰▶ see: https://nuxt.com/e/b2011
```

## What it means

Nuxt resolves a plugin's execution environment from two sources: the filename suffix (`.client.ts`, `.server.ts`) and the explicit `mode` field on a plugin registration. When they disagree, Nuxt emits this diagnostic so the conflict is resolved before the app starts.

## Common causes

- A plugin file was renamed from `.client.ts` to `.server.ts` without updating `mode`.
- A module option switches the plugin mode but not the resolved file path.
- A shared helper applies a default `mode` after the plugin path was already selected.

## How to fix

The preferred fix is to remove `mode` and let the filename suffix decide:

```ts [app/plugins/analytics.server.ts]
export default defineNuxtPlugin(() => {
  // plugin code
})
```

Alternatively, keep the explicit `mode` and rename the file to match:

```ts [app/plugins/analytics.ts]
export default defineNuxtPlugin({
  mode: 'server',
  setup() {
    // plugin code
  },
})
```

## For module authors

Modules that register plugins programmatically can emit this diagnostic using the
[nostics](https://github.com/vercel-labs/nostics) API. The `why` and `fix` functions receive typed
parameters, so the message reflects the actual file path and modes involved:

```ts
import { defineDiagnostics, createConsoleReporter } from 'nostics'

const diagnostics = defineDiagnostics({
  docsBase: (code) => `https://nuxt.com/e/${code.replace('NUXT_', '').toLowerCase()}`,
  reporters: [createConsoleReporter()],
  codes: {
    NUXT_B2011: {
      why: ({ src, registeredMode, suffixMode }: { src: string; registeredMode: 'client' | 'server'; suffixMode: 'client' | 'server' }) =>
        `Plugin \`${src}\` is ${suffixMode}-only but was registered with mode \`${registeredMode}\`.`,
      fix: ({ src, suffixMode }: { src: string; registeredMode: 'client' | 'server'; suffixMode: 'client' | 'server' }) =>
        `Rename the file to remove the suffix, or register it with mode \`${suffixMode}\`.`,
    },
  },
})

// Diagnostics extend Error and can be thrown directly.
throw diagnostics.NUXT_B2011({
  src: plugin.src,
  registeredMode: plugin.mode,
  suffixMode: resolvedSuffix,
  sources: [{ file: 'nuxt.config.ts', line: 12, col: 5 }],
})
```

## See also

- [Nuxt plugins](https://nuxt.com/docs/guide/directory-structure/plugins)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
