---
layout: doc
title: KUBB_HOOK_FAILED
description: The KUBB_HOOK_FAILED diagnostic fires when a post-generate hooks.done command exits with a non-zero status.
outline: [2, 3]
---

# KUBB_HOOK_FAILED: Hook failed

Code: `KUBB_HOOK_FAILED`
Level: error

A post-generate shell hook (`hooks.done`) exited with a non-zero status. Hooks run after
generation, so the files are written, but the run is marked failed.

## What happened

`hooks.done` runs shell commands once generation finishes, for example a formatter or a `tsc`
check. A command that exits non-zero is reported here. It used to only log a line. Now it shows in
the summary and `--reporter json`, and fails the run instead of being swallowed.

## Common causes

- The command is not installed or not on `PATH`.
- A typo in the command.
- The command does real work and genuinely failed (a type error caught by `tsc`, for example).

## How to fix it

- Run the command manually from the project root to see its output.
- Confirm the binary is installed and the command is spelled correctly.

```typescript
import { defineConfig } from 'kubb'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: { path: './src/gen' },
  hooks: {
    done: ['biome check --write ./src/gen'],
  },
})
```

## Example output

```txt
[KUBB_HOOK_FAILED]: Post-generate hook failed
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-hook-failed
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
