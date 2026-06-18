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
[KUBB_UPDATE_AVAILABLE] Update available: v5.0.0 → v5.1.0. Run `npm install -g @kubb/cli` to update.
```

## What happened

Before generating, the CLI checks npm for a newer release. When one exists, it reports this notice. It is informational and never fails the build. The check is skipped when you are offline.

## How to fix it

Update the `@kubb/*` packages to pick up the latest fixes.

```shell [Terminal]
npm install -g @kubb/cli@beta
```

Update the per-project plugins through your package manager as well, for example.

```shell [Terminal]
npm install @kubb/adapter-oas@beta @kubb/plugin-ts@beta
```

## See also

- [`kubb generate`](/docs/5.x/api/commands/generate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
