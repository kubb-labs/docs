---
layout: doc
title: KUBB_UNSUPPORTED_FORMAT
description: The KUBB_UNSUPPORTED_FORMAT diagnostic fires when a schema uses a format Kubb does not map to a specific type.
outline: [2, 3]
---

# KUBB_UNSUPPORTED_FORMAT

**Severity:** warning · **Source:** OpenAPI adapter

A schema's `format` is not one Kubb maps to a specific type, so it falls back to the base type.

```sh
⚠ @kubb/adapter-oas(KUBB_UNSUPPORTED_FORMAT): Kubb does not map the format "snowflake" to a specific type, so it falls back to the base type.
  at #/components/schemas/Pet/properties/id
  help: Use a format Kubb supports, or handle "snowflake" with a custom parser or plugin.
  docs: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-unsupported-format
```

## What it means

While walking the named component schemas, the OpenAPI adapter found a `format` it has no specific mapping for. Generation continues with the base type (for example `string`), so this is a warning, not a failure. The adapter reports it on every run.

## Common causes

- A vendor-specific format such as `snowflake` or `money` that has no built-in mapping.
- A typo in a standard format, like `date-tine` instead of `date-time`.

## Example

```yaml
components:
  schemas:
    Pet:
      type: object
      properties:
        id:
          type: string
          format: snowflake # falls back to string
```

## How to fix

- Use a format Kubb supports, or drop the `format` if the base type is enough.
- Handle the custom format with a parser or plugin that maps it to the type you want.

## See also

- [`kubb validate`](/docs/5.x/api/commands/validate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
