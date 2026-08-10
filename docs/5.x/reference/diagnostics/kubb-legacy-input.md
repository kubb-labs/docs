---
layout: doc
title: KUBB_LEGACY_INPUT
description: The KUBB_LEGACY_INPUT diagnostic fires when input still uses the v4 path or data wrapper.
outline: [2, 3]
---

# KUBB_LEGACY_INPUT: Legacy input shape

Code: `KUBB_LEGACY_INPUT`
Level: error

`input` is a `{ path }` or `{ data }` wrapper. v4 used it to point at a document, and v5 takes the value directly.

## What happened

In v4, `input` was an object that wrapped the real value: `{ path: './petStore.yaml' }` for a file and `{ data: spec }` for a parsed document. v5 collapses both into a single `input` value and works out what it is.

The wrapper is still a plain object, so without this check Kubb took it for an already-parsed document and generated from `{ path: './petStore.yaml' }` as if that were the spec. Nothing matched, so the run wrote no types or clients yet still reported success and exited `0`. That let a config left over from v4 pass CI with an empty client, which is why the wrapper is now rejected outright.

## How to fix it

Unwrap the value.

```diff [kubb.config.ts]
-  input: { path: './petStore.yaml' },
+  input: './petStore.yaml',
```

The same applies to a parsed document.

```diff [kubb.config.ts]
-  input: { data: spec },
+  input: spec,
```

## Example

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  // the v4 wrapper, no longer accepted
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  plugins: [/* ... */],
})
```

## Example output

```text [Terminal]
[KUBB_LEGACY_INPUT]: The `input` option uses the v4 `{ path }` / `{ data }` wrapper.
  fix: Unwrap it: `input: { path: "./petStore.yaml" }` becomes `input: "./petStore.yaml"`, and `input: { data: spec }` becomes `input: spec`.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-legacy-input
```

## See also

- [Migrating to v5](/docs/5.x/migration#give-input-a-single-value)
- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
