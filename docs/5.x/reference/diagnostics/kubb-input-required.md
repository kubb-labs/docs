---
layout: doc
title: KUBB_INPUT_REQUIRED
description: The KUBB_INPUT_REQUIRED diagnostic fires when an adapter is configured but no input was provided.
outline: [2, 3]
---

# KUBB_INPUT_REQUIRED: Input required

Code: `KUBB_INPUT_REQUIRED`
Level: error

An adapter is configured but no `input` was provided, so there is nothing to parse.

## What happened

The adapter needs a source document. It reads one from `input.path` (a file or URL) or `input.data` (an inline spec). This diagnostic fires when neither is set. It also fires when merging is requested but no documents are passed.

## How to fix it

Set `input.path` to a file or URL.

```typescript
input: { path: './petStore.yaml' }
```

Or pass an inline spec with `input.data`.

```typescript
input: { data: openapiObject }
```

## Example

```typescript twoslash
import { defineConfig } from 'kubb'

export default defineConfig({
  // input is missing
  output: { path: './src/gen' },
  plugins: [/* ... */],
})
```

## Example output

```txt
[KUBB_INPUT_REQUIRED] @kubb/adapter-oas: An adapter is configured without an input.
  fix: Provide `input.path` (a file or URL) or `input.data` (an inline spec) in your Kubb config.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-required
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
