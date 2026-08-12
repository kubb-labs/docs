---
layout: doc
title: KUBB_INPUT_NOT_FOUND
description: The KUBB_INPUT_NOT_FOUND diagnostic fires when the file set as input (or passed to kubb generate) cannot be read.
outline: [2, 3]
---

# KUBB_INPUT_NOT_FOUND: Input not found

Code: `KUBB_INPUT_NOT_FOUND`
Level: error

The file set as `input` (or passed as `kubb generate PATH`) could not be read. The OpenAPI adapter checks the path before parsing, so the run stops here instead of failing later with a vague read error.

## What happened

Kubb resolves a file `input` relative to the config file, then confirms the file exists before reading it. This diagnostic fires when nothing is there. URLs skip this check and report on the request instead: [`KUBB_INPUT_REQUEST_FAILED`](/docs/5.x/reference/diagnostics/kubb-input-request-failed) for a 4xx or 5xx status, and [`KUBB_INPUT_UNREACHABLE`](/docs/5.x/reference/diagnostics/kubb-input-unreachable) when the host never answers.

## Common causes

- A typo in `input`, or a path relative to the wrong directory.
- The spec was moved or renamed but the config still points at the old location.
- `kubb generate ./spec.yaml` ran from a directory where that relative path does not resolve.

## How to fix it

- Check the path exists and is readable, then set it as `input` or pass it as `kubb generate PATH`.
- Use a path relative to your `kubb.config.ts`, or an absolute path.
- For a remote spec, set `input` to the full URL.

## Example output

```text [Terminal]
[KUBB_INPUT_NOT_FOUND]: Cannot read the file set as `input` (or via `kubb generate PATH`): ./petStore.yaml
  fix: Check that the path exists and is readable, then set it as `input` or pass it as `kubb generate PATH`.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-not-found
```

## See also

- [`KUBB_INPUT_REQUEST_FAILED`](/docs/5.x/reference/diagnostics/kubb-input-request-failed)
- [`KUBB_INPUT_UNREACHABLE`](/docs/5.x/reference/diagnostics/kubb-input-unreachable)
- [Configuration](/docs/5.x/reference/configuration)
- [`kubb generate`](/docs/5.x/reference/commands/generate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
