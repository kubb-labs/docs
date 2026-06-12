---
layout: doc
title: KUBB_LINT_FAILED
description: The KUBB_LINT_FAILED diagnostic fires when the linter pass over the generated files fails.
outline: [2, 3]
---

# KUBB_LINT_FAILED

**Severity:** error · **Source:** CLI

The linter pass over the generated files failed. Linting runs after generation, so the files are
written, but the run is marked failed.

```sh
× (KUBB_LINT_FAILED): linter failed
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-lint-failed
```

## What it means

When `output.lint` is set, Kubb runs the configured linter (oxlint, biome, or eslint) over the
output directory. A non-zero exit from the linter is reported here. It used to be swallowed. Now it
shows in the summary and `--reporter json`, and fails the run.

## Common causes

- The linter is not installed in the project.
- The linter config is invalid or points at a missing file.
- Lint rules that flag the generated code as errors.

## How to fix

- Confirm the linter is installed and its config is valid.
- Run it manually on the output to see the underlying error, for example `oxlint ./src/gen`.
- Relax the rules for generated files, or remove `output.lint` if you do not want a linter pass.

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [`KUBB_FORMAT_FAILED`](/docs/5.x/reference/diagnostics/kubb-format-failed)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
