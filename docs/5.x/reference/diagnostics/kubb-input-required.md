---
layout: doc
title: KUBB_INPUT_REQUIRED
description: The KUBB_INPUT_REQUIRED diagnostic fires when an adapter is configured but no input was provided.
outline: [2, 3]
---

# KUBB_INPUT_REQUIRED

**Severity:** error · **Source:** OpenAPI adapter

An adapter is configured but no `input` was provided, so there is nothing to parse.

```sh
× @kubb/adapter-oas(KUBB_INPUT_REQUIRED): An adapter is configured without an input.
  help: Provide `input.path` (a file or URL) or `input.data` (an inline spec) in your Kubb config.
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-required
```

## What it means

The adapter needs a source document. It reads one from `input.path` (a file or URL) or
`input.data` (an inline spec). This diagnostic fires when neither is set, including the case where
merging is asked for but no documents are passed.

## Example

```typescript
import { defineConfig } from 'kubb'

export default defineConfig({
  // input is missing
  output: { path: './src/gen' },
  plugins: [/* ... */],
})
```

## How to fix

- Set `input.path` to a file or URL:

  ```typescript
  input: { path: './petStore.yaml' }
  ```

- Or pass an inline spec with `input.data`:

  ```typescript
  input: { data: openapiObject }
  ```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
