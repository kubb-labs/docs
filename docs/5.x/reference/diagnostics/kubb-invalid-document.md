---
layout: doc
title: KUBB_INVALID_DOCUMENT
description: The KUBB_INVALID_DOCUMENT diagnostic fires when the resolved input is not an OpenAPI or Swagger document.
outline: [2, 3]
---

# KUBB_INVALID_DOCUMENT: Invalid document

Code: `KUBB_INVALID_DOCUMENT`
Level: error

The document resolved from `input` declares neither `openapi` nor `swagger`, so the adapter has nothing to read it as.

## What happened

Spec violations are deliberately non-fatal: a document that bends the rules but still describes an API generates fine, and the problems are reported without failing the run. A missing version field is different. It means the input is not an OpenAPI or Swagger document at all, so there are no operations or schemas to find and every generator would produce nothing.

Before this check, that case fell under the same leniency and the run exited `0` after writing only the runtime helpers. Pointing `input` at the wrong JSON file, or at an object that wraps the spec rather than the spec itself, now fails immediately instead.

This check runs whether or not `validate` is enabled. Every other validation failure still respects `validate` and stays non-fatal.

## How to fix it

Point `input` at a document that declares its version.

```yaml [petStore.yaml]
openapi: 3.1.0
info:
  title: Pet Store
  version: 1.0.0
```

If you pass an object, pass the spec itself rather than a wrapper around it.

```diff [kubb.config.ts]
-  input: { path: './petStore.yaml' },
+  input: './petStore.yaml',
```

## Example

```typescript [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  // package.json parses fine, but it is not a spec
  input: './package.json',
  output: { path: './src/gen' },
  plugins: [/* ... */],
})
```

## Example output

```text [Terminal]
[KUBB_INVALID_DOCUMENT]: The resolved `input` is not an OpenAPI or Swagger document: it declares no `openapi` or `swagger` version.
  fix: Point `input` at a document that declares `openapi` or `swagger`. If you pass an object, pass the spec itself rather than a wrapper such as `{ path }` or `{ data }`.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-invalid-document
```

## See also

- [`KUBB_LEGACY_INPUT`](/docs/5.x/reference/diagnostics/kubb-legacy-input)
- [`@kubb/adapter-oas`](/adapters/adapter-oas/)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
