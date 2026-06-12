---
layout: doc
title: KUBB_UNKNOWN
description: The KUBB_UNKNOWN diagnostic, a build error that does not yet carry a specific code.
outline: [2, 3]
---

# KUBB_UNKNOWN

**Severity:** error · **Source:** core

A fallback for an error that does not yet carry a specific diagnostic code.

```sh
× KUBB_UNKNOWN: Cannot read properties of undefined (reading 'name')
```

## What it means

Kubb wraps every failure in a diagnostic. When the underlying error has no structured code, it is
reported as `KUBB_UNKNOWN` with the original message. There is no `help:` or `docs:` line because
the failure mode is not yet classified.

## Common causes

- An unexpected error inside a plugin or generator.
- An error thrown by a dependency that Kubb does not yet recognize.
- A bug in Kubb itself.

## How to fix

- Re-run with `kubb generate --reporter file` to write a log to `.kubb/kubb-<timestamp>.log`, or `--verbose` for more detail in the terminal.
- Check the message and stack for the failing plugin or input.
- If the cause is unclear, open a [GitHub issue](https://github.com/kubb-labs/kubb/issues) with the
  message and the `Environment:` block from the failure summary.

## See also

- [Diagnostics reference](/docs/5.x/reference/diagnostics)
- [`kubb generate`](/docs/5.x/api/commands/generate)
