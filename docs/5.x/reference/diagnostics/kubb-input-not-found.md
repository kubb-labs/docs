---
layout: doc
title: KUBB_INPUT_NOT_FOUND
description: The KUBB_INPUT_NOT_FOUND diagnostic fires when the file set in input.path (or passed to kubb generate) cannot be read.
outline: [2, 3]
---

# KUBB_INPUT_NOT_FOUND: Input not found

Code: `KUBB_INPUT_NOT_FOUND`
Level: error

The file set in `input.path` (or passed as `kubb generate PATH`) could not be read. The OpenAPI adapter checks the path before parsing, so the run stops here instead of failing later with a vague read error.

## What happened

Kubb resolves `input.path` relative to the config file, then confirms the file exists before reading it. This diagnostic fires when nothing is there. URLs skip this check, so a remote spec surfaces its own fetch error instead.

## Common causes

- A typo in `input.path`, or a path relative to the wrong directory.
- The spec was moved or renamed but the config still points at the old location.
- `kubb generate ./spec.yaml` ran from a directory where that relative path does not resolve.

## How to fix it

- Check the path exists and is readable, then set it in `input.path` or pass it as `kubb generate PATH`.
- Use a path relative to your `kubb.config.ts`, or an absolute path.
- For a remote spec, set `input.path` to the full URL.

## Example output

```text [Terminal]
[KUBB_INPUT_NOT_FOUND] @kubb/adapter-oas: Cannot read the file set in `input.path` (or via `kubb generate PATH`): ./petStore.yaml
  fix: Check that the path exists and is readable, then set it in `input.path` or pass it as `kubb generate PATH`.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-not-found
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [`kubb generate`](/docs/5.x/reference/commands/generate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
