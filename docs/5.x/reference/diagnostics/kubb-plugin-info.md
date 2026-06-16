---
layout: doc
title: KUBB_PLUGIN_INFO
description: The KUBB_PLUGIN_INFO diagnostic carries an informational message a plugin reported through ctx.info.
outline: [2, 3]
---

# KUBB_PLUGIN_INFO

**Severity:** info · **Source:** Plugin

A plugin reported an informational message through `ctx.info`. It is advisory and does not fail the
run.

```sh
ℹ @kubb/plugin-client(KUBB_PLUGIN_INFO): Using fetch as the HTTP client.
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-plugin-info
```

## What it means

A plugin surfaced context about what it did. The message carries the plugin name and appears in the
run summary and in `kubb generate --reporter json`.

## How to fix

It is informational, so no action is required.

## For plugin authors

`ctx.info(message)` reports a `KUBB_PLUGIN_INFO`. For a stable code and a source pointer, build an
`info` diagnostic and call `Diagnostics.report(...)` instead.

## See also

- [`KUBB_PLUGIN_WARNING`](/docs/5.x/reference/diagnostics/kubb-plugin-warning)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
