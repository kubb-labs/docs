---
layout: doc
title: KUBB_PLUGIN_WARNING
description: The KUBB_PLUGIN_WARNING diagnostic carries a non-fatal warning a plugin reported through ctx.warn.
outline: [2, 3]
---

# KUBB_PLUGIN_WARNING: Plugin warning

Code: `KUBB_PLUGIN_WARNING`
Level: warning

A plugin reported a non-fatal warning through `ctx.warn`. Kubb collects and shows it, but it does not fail the run.

## What happened

A plugin found something worth flagging but could still generate. The warning carries the plugin name and appears in the run summary and in `kubb generate --reporter json`.

## How to fix it

Read the message and adjust the plugin options or the input if the warning is unwanted. Nothing is required to make the build pass. A warning never fails a run.

## For plugin authors

`ctx.warn(message)` reports a `KUBB_PLUGIN_WARNING`. For a stable code and a source pointer, build a `warning` diagnostic and call `Diagnostics.report(...)` instead.

## Example output

```txt
[KUBB_PLUGIN_WARNING] @kubb/plugin-zod: Falling back to z.any() for an untyped schema.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-plugin-warning
```

## See also

- [`KUBB_PLUGIN_FAILED`](/docs/5.x/reference/diagnostics/kubb-plugin-failed)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
