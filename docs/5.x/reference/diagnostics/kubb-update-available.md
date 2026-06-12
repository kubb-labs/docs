---
layout: doc
title: KUBB_UPDATE_AVAILABLE
description: The KUBB_UPDATE_AVAILABLE diagnostic tells you a newer Kubb version is published on npm.
outline: [2, 3]
---

# KUBB_UPDATE_AVAILABLE

**Severity:** info · **Source:** CLI

A newer Kubb version is published on npm than the one running.

```sh
ℹ (KUBB_UPDATE_AVAILABLE): Update available: v5.0.0 → v5.1.0. Run `npm install -g @kubb/cli` to update.
```

## What it means

Before generating, the CLI checks npm for a newer release. When one exists, it reports this notice.
It is informational, so it never fails the build. The check is skipped when you are offline.

## How to fix

Update the `@kubb/*` packages to pick up the latest fixes:

```shell
npm install -g @kubb/cli
```

Update the per-project plugins through your package manager as well, for example:

```shell
npm install @kubb/adapter-oas@latest @kubb/plugin-ts@latest
```

## See also

- [`kubb generate`](/docs/5.x/api/commands/generate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
