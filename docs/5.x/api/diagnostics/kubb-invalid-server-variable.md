---
layout: doc
title: KUBB_INVALID_SERVER_VARIABLE
description: The KUBB_INVALID_SERVER_VARIABLE diagnostic, raised when a server URL variable value is not one of the values its enum allows.
outline: [2, 3]
---

# KUBB_INVALID_SERVER_VARIABLE: Invalid server variable

Code: `KUBB_INVALID_SERVER_VARIABLE`
Level: error

A server variable resolves to a value that its `enum` does not allow.

## What happened

OpenAPI server URLs can contain `{variable}` placeholders. When a variable declares an `enum`, the value Kubb resolves it to must be in that list. This diagnostic fires when the resolved value is not.

## How to fix it

- Pass a value that the `enum` allows, or make the `default` a member of the `enum`.
- Add the value to the `enum` if the server supports it.
- Remove the `enum` if the variable is open-ended.

## Common causes

- An override passed to Kubb uses a value outside the variable's `enum`.
- The variable's `default` is not itself a member of its `enum`.
- The `enum` list is missing a value that the server actually supports.

## Example

```yaml [petStore.yaml]
servers:
  - url: https://{env}.api.example.com
    variables:
      env:
        default: dev
        enum: [dev, prod]   # 'staging' is not allowed
```

## Example output

```text [Terminal]
[KUBB_INVALID_SERVER_VARIABLE]: Invalid server variable value 'staging' for 'env' when resolving https://{env}.api.example.com. Valid values are: dev, prod.
  at: #/servers
  fix: Use one of the allowed enum values, or drop the enum on the 'env' server variable.
  see: https://kubb.dev/docs/5.x/api/diagnostics/kubb-invalid-server-variable
```

## See also

- [Base URL guide](/docs/5.x/guide/going-further/base-url)
- [Diagnostics reference](/docs/5.x/api/diagnostics)
