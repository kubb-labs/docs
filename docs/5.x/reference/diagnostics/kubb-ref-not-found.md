---
layout: doc
title: KUBB_REF_NOT_FOUND
description: The KUBB_REF_NOT_FOUND diagnostic, raised when a $ref in your OpenAPI document points at a definition Kubb cannot resolve.
outline: [2, 3]
---

# KUBB_REF_NOT_FOUND: Reference not found

Code: `KUBB_REF_NOT_FOUND`
Level: error

A `$ref` points at a definition that does not exist in the document.

## What happened

Kubb resolves local references (`#/...`) against the document it parsed. This diagnostic fires when
a reference points at a path that is not there, so the schema or operation it belongs to cannot be
generated.

## How to fix it

- Add the missing definition under `components.schemas`, or correct the `$ref` to match an existing
  one.
- Run [`kubb validate`](/docs/5.x/api/commands/validate) to catch unresolved references before
  generating.
- If the target lives in another file, bundle the document first so all references are local.

## Common causes

- A typo in the `$ref` path, such as a wrong casing or a missing segment.
- The referenced schema was renamed or removed but a reference still points at the old name.
- The reference targets a component in another file that was not bundled into the document.
- A circular or partial spec where the target is defined elsewhere.

## Example

```yaml
paths:
  /pets:
    get:
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Pet'   # Pet is never defined
```

## Example output

```txt
[KUBB_REF_NOT_FOUND] @kubb/plugin-zod: Could not find a definition for #/components/schemas/Pet.
├▶ at: #/components/schemas/Pet
├▶ fix: Add the schema under components.schemas, or fix the $ref. Run `kubb validate` to check the spec.
╰▶ see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-ref-not-found
```

## See also

- [`kubb validate`](/docs/5.x/api/commands/validate)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
