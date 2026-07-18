---
layout: doc
title: KUBB_UNSUPPORTED_FORMAT
description: The KUBB_UNSUPPORTED_FORMAT diagnostic fires when a schema uses a format Kubb does not map to a specific type.
outline: [2, 3]
---

# KUBB_UNSUPPORTED_FORMAT: Unsupported format

Code: `KUBB_UNSUPPORTED_FORMAT`
Level: warning

A schema's `format` is not one Kubb maps to a specific type, so it falls back to the base type.

## What happened

While walking the named component schemas, the OpenAPI adapter found a `format` it has no specific mapping for. Generation continues with the base type, for example `string`. This is a warning, not a failure. The adapter reports it on every run.

## How to fix it

- Use a format Kubb supports, or drop the `format` if the base type is enough.
- Handle the custom format with a parser or plugin that maps it to the type you want.

## Common causes

- A vendor-specific format such as `snowflake` or `money` that has no built-in mapping.
- A typo in a standard format, such as `date-tine` instead of `date-time`.

## Example

```yaml [petStore.yaml]
components:
  schemas:
    Pet:
      type: object
      properties:
        id:
          type: string
          format: snowflake # falls back to string
```

## Example output

```text [Terminal]
[KUBB_UNSUPPORTED_FORMAT]: Kubb does not map the format "snowflake" to a specific type, so it falls back to the base type.
  at: #/components/schemas/Pet/properties/id
  fix: Use a format Kubb supports, or handle "snowflake" with a custom parser or plugin.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-unsupported-format
```

## See also

- [`kubb validate`](/docs/5.x/reference/commands/validate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
