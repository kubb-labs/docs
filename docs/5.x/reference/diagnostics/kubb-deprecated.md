---
layout: doc
title: KUBB_DEPRECATED
description: The KUBB_DEPRECATED diagnostic flags a schema or operation marked deprecated in your OpenAPI document.
outline: [2, 3]
---

# KUBB_DEPRECATED: Deprecated

Code: `KUBB_DEPRECATED`
Level: info

A referenced schema or operation is marked `deprecated`.

## What happened

The OpenAPI adapter found a `deprecated: true` on a schema while walking the named component schemas. Kubb still generates it. This is informational, so it does not fail the build. The adapter reports it on every run.

## How to fix it

- Migrate off the deprecated definition if the notice is unwanted.
- Leave it in place if you still depend on it. The diagnostic is informational and changes nothing about the output.

## Example

```yaml
components:
  schemas:
    Pet:
      type: object
      deprecated: true
      properties:
        id:
          type: string
```

## Example output

```txt
[KUBB_DEPRECATED] @kubb/adapter-oas: This schema is marked as deprecated.
  at: #/components/schemas/Pet
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-deprecated
```

## See also

- [`kubb validate`](/docs/5.x/api/commands/validate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
