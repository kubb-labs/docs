---
layout: doc
title: KUBB_FORMAT_FAILED
description: The KUBB_FORMAT_FAILED diagnostic fires when the formatter pass over the generated files fails.
outline: [2, 3]
---

# KUBB_FORMAT_FAILED: Format failed

Code: `KUBB_FORMAT_FAILED`
Level: error

The formatter pass over the generated files failed. Formatting runs after generation. The files are written, but the run is marked failed.

## What happened

When `output.format` is set, Kubb runs the configured formatter (oxfmt, biome, or prettier) over the output directory. A non-zero exit from the formatter shows up here, in the summary, and in `--reporter json`. It fails the run. Earlier versions swallowed it, so a broken formatter config went unnoticed.

## How to fix it

- Confirm the formatter is installed and its config is valid.
- Run it manually on the output to see the underlying error, for example `biome check --write ./src/gen`.
- Remove or change `output.format` if you do not want a formatter pass.

## Common causes

- The formatter is not installed in the project.
- The formatter config is invalid or points at a missing file.
- The formatter rejects the generated code.

## Example output

```text [Terminal]
[KUBB_FORMAT_FAILED]: formatter failed
  see: https://kubb.dev/docs/5.x/api/diagnostics/kubb-format-failed
```

## See also

- [Configuration](/docs/5.x/api/configuration)
- [`KUBB_LINT_FAILED`](/docs/5.x/api/diagnostics/kubb-lint-failed)
- [Diagnostics reference](/docs/5.x/api/diagnostics)
