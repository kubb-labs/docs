---
layout: doc
title: KUBB_PLUGIN_FAILED
description: The KUBB_PLUGIN_FAILED diagnostic fires when a plugin throws while generating or reports an error through ctx.error.
outline: [2, 3]
---

# KUBB_PLUGIN_FAILED: Plugin failed

Code: `KUBB_PLUGIN_FAILED`
Level: error

A plugin threw while generating, or reported an error through `ctx.error`. The diagnostic is attributed to the plugin and fails the run.

## What happened

Each plugin runs against the AST and can fail on a specific schema or operation. A thrown error or a `ctx.error(...)` call lands here, carrying the plugin name. When the plugin passed an `Error`, Kubb keeps it as the diagnostic `cause`, so the underlying stack is preserved.

## Common causes

- An option the plugin does not accept, or a missing required option.
- A schema or operation shape the plugin cannot map.
- A bug in the plugin, surfaced as a thrown error.

## How to fix it

- Read the underlying message and check the plugin's options against its docs.
- Inspect the schema or operation the message points at.
- If it looks like a plugin bug, report it with the spec fragment that triggers it.

## For plugin authors

`ctx.error` reports a `KUBB_PLUGIN_FAILED` and fails the build. For a structured diagnostic with a stable code and a source pointer, call `Diagnostics.report(...)` or throw a `DiagnosticError` instead.

```typescript twoslash [plugin.ts]
import { Diagnostics } from 'kubb/kit'

Diagnostics.report({
  code: 'KUBB_REF_NOT_FOUND',
  severity: 'error',
  message: 'Could not find a definition for Pet.',
  location: { kind: 'schema', pointer: '#/components/schemas/Pet' },
  help: 'Add the schema under components.schemas, or fix the $ref.',
})
```

## Example output

```text [Terminal]
[KUBB_PLUGIN_FAILED] @kubb/plugin-ts: Cannot generate type for operation getPetById.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-plugin-failed
```

## See also

- [Plugins](/plugins)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
