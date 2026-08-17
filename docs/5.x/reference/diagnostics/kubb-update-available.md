---
layout: doc
title: KUBB_UPDATE_AVAILABLE
description: The KUBB_UPDATE_AVAILABLE diagnostic tells you a newer Kubb version is published on npm.
outline: [2, 3]
---

# KUBB_UPDATE_AVAILABLE: Update available

Code: `KUBB_UPDATE_AVAILABLE`
Level: info

A newer Kubb version is published on npm than the one running.

```text [Terminal]
╭─────── Update available for `Kubb` ───────╮
│                                           │
│           `v5.0.0` → `v5.1.0`             │
│  Run `npm install -g @kubb/cli` to update │
│                                           │
╰───────────────────────────────────────────╯
```

## What happened

Before generating, the CLI checks npm for a newer release. When one exists, it reports this notice. It is informational and never fails the build. The check is skipped when you are offline.

This is the one diagnostic the interactive logger renders as a framed box rather than a code-tagged line. When output is not a TTY, such as in CI, it falls back to the standard diagnostic format:

```text [Terminal]
[KUBB_UPDATE_AVAILABLE]: Update available: v5.0.0 → v5.1.0. Run `npm install -g @kubb/cli` to update.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-update-available
```

## How to fix it

Update the `@kubb/*` packages to pick up the latest fixes.

```shell [Terminal]
npm install -g @kubb/cli@5.0.0
```

Update the per-project plugins through your package manager as well, for example.

```shell [Terminal]
npm install @kubb/adapter-oas@5.0.0 @kubb/plugin-ts@5.0.0
```

## See also

- [`kubb generate`](/docs/5.x/reference/commands/generate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
