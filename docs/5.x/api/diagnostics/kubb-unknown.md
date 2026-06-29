---
layout: doc
title: KUBB_UNKNOWN
description: The KUBB_UNKNOWN diagnostic, a build error that does not yet carry a specific code.
outline: [2, 3]
---

# KUBB_UNKNOWN: Unknown error

Code: `KUBB_UNKNOWN`
Level: error

A fallback for an error that does not yet carry a specific diagnostic code.

## What happened

Kubb wraps every failure in a diagnostic. When the underlying error has no structured code, Kubb reports it as `KUBB_UNKNOWN` with the original message. There is no `fix:` or `see:` line because the failure mode is not yet classified.

## Common causes

- An unexpected error inside a plugin or generator.
- An error thrown by a dependency that Kubb does not yet recognize.
- A bug in Kubb itself.

## How to fix it

- Re-run with `kubb generate --reporter file` to write a log to `.kubb/kubb-<timestamp>.log`, or `--verbose` for more detail in the terminal.
- Check the message and stack for the failing plugin or input.
- If the cause is unclear, open a [GitHub issue](https://github.com/kubb-labs/kubb/issues) with the message and the `Environment:` block from the failure summary.

## Example output

```text [Terminal]
[KUBB_UNKNOWN]: Cannot read properties of undefined (reading 'name')
```

## See also

- [Diagnostics reference](/docs/5.x/api/diagnostics)
- [`kubb generate`](/docs/5.x/api/commands/generate)
