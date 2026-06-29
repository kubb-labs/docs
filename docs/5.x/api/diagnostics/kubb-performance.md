---
layout: doc
title: KUBB_PERFORMANCE
description: The KUBB_PERFORMANCE diagnostic records how long a plugin took, feeding the run summary and timing bars.
outline: [2, 3]
---

# KUBB_PERFORMANCE: Performance

Code: `KUBB_PERFORMANCE`
Level: info

Records a plugin's elapsed time. Kubb collects one per plugin during a build.

## What happened

This is bookkeeping, not a problem. Kubb attaches a `KUBB_PERFORMANCE` record to every plugin with the milliseconds it took to generate. It never fails the build. It is not printed in the terminal as a diagnostic.

It surfaces in two places.

- The run total `durationMs` in the [`--reporter json`](/docs/5.x/api/commands/generate#reporters) report is the sum of every `KUBB_PERFORMANCE` record.
- The per-plugin timing bars in the end-of-run summary, shown with `--verbose`.

```shell [Terminal]
kubb generate --verbose
```

```shell [Terminal]
 Plugins  3 passed (3)
   Files  12 generated
Duration  81ms
  Output  ./src/gen
 Timings
          • @kubb/plugin-react-query ████ 42ms
          • @kubb/plugin-zod         ██ 21ms
          • @kubb/plugin-ts          ██ 18ms
```

The total is the sum of plugin timings, so it counts generation only. It leaves out the config load, the formatter, the linter, and post-generate hooks.

## How to fix it

Nothing to fix. To find a slow plugin, run `kubb generate --verbose` and read the timing bars. Then review that plugin's options or the schemas it generates.

## See also

- [`kubb generate`](/docs/5.x/api/commands/generate)
- [Diagnostics reference](/docs/5.x/api/diagnostics)
