---
layout: doc
title: KUBB_CLEAN_ROOT
description: The KUBB_CLEAN_ROOT diagnostic fires when output.clean would delete the project root instead of only the generated code.
outline: [2, 3]
---

# KUBB_CLEAN_ROOT: Clean targets the project root

Code: `KUBB_CLEAN_ROOT`
Level: error

`output.clean` removes generated code before a build. Kubb stops the build instead of wiping your project when `output.path` resolves to the project root or a parent of it, which would delete `kubb.config` and every source file.

## What happened

Before a build, `output.clean` empties the output directory. Kubb resolves `output.path` against `root` and checks whether the result is the project root itself, or a directory that contains it (for example `path: '.'`, `'./'`, or `'..'`). If so, the clean would remove more than generated code, so the build stops here.

## How to fix it

- Point `output.path` at a subdirectory such as `./src/gen`, so clean only removes generated code.
- Turn off `output.clean` when you keep hand-written files next to the generated ones.

## Common causes

- `output.path` set to `.` or `./` while `output.clean` is enabled.
- A `root` that already points at the generated folder, paired with an `output.path` that climbs above it with `..`.

## Example output

```text [Terminal]
[KUBB_CLEAN_ROOT]: output.clean cannot delete "/app" because it is the project root or a parent of it.
  fix: Point `output.path` at a subdirectory such as `./src/gen` so clean only removes generated code.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-clean-root
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
