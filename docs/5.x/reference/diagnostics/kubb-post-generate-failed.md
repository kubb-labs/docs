---
layout: doc
title: KUBB_POST_GENERATE_FAILED
description: The KUBB_POST_GENERATE_FAILED diagnostic fires when a post-generate output.postGenerate command exits with a non-zero status.
outline: [2, 3]
---

# KUBB_POST_GENERATE_FAILED: Post-generate command failed

Code: `KUBB_POST_GENERATE_FAILED`
Level: error

A post-generate command (`output.postGenerate`) exited with a non-zero status. These commands run after generation. The files are written, but the run is marked failed.

## What happened

`output.postGenerate` runs shell commands once the generated files are formatted and linted, for example a formatter or a `tsc` check. A command that exits non-zero shows up here, in the summary, and in `--reporter json`. Earlier versions only logged a line and moved on.

## Common causes

- The command is not installed or not on `PATH`.
- The command has a typo.
- The command did real work and genuinely failed, such as a type error caught by `tsc`.

## How to fix it

- Run the command manually from the project root to see its output.
- Confirm the binary is installed and the command is spelled correctly.

```typescript twoslash [kubb.config.ts]
import { defineConfig } from 'kubb/config'

export default defineConfig({
  input: { path: './petStore.yaml' },
  output: {
    path: './src/gen',
    postGenerate: ['biome check --write ./src/gen'],
  },
})
```

## Example output

```text [Terminal]
[KUBB_POST_GENERATE_FAILED]: Post-generate command failed
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-post-generate-failed
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
