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

The adapter needs a source document, read from `input`: a file path, a URL, an inline spec, or a parsed object. This diagnostic fires when `input` is not set, or when merging is requested but no documents are passed.

## How to fix it

Set `input` to a file path or URL.

```typescript [kubb.config.ts]
input: './petStore.yaml'
```

Or pass an inline spec or a parsed object.

```typescript [kubb.config.ts]
input: openapiObject
```

## Example

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  // input is missing
  output: { path: './src/gen' },
  plugins: [/* ... */],
})
```

## Example output

```text [Terminal]
[KUBB_INPUT_REQUIRED]: An adapter is configured without an input.
  fix: Set `input` to a file path, a URL, an inline spec (JSON/YAML string), or a parsed object in your Kubb config.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-required
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
