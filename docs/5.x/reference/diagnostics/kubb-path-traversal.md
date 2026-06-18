---
layout: doc
title: KUBB_PATH_TRAVERSAL
description: The KUBB_PATH_TRAVERSAL diagnostic fires when a resolved output path escapes the configured output directory.
outline: [2, 3]
---

# KUBB_PATH_TRAVERSAL: Path traversal

Code: `KUBB_PATH_TRAVERSAL`
Level: error

A resolved output path escaped the output directory. Kubb refuses to write outside `output.path`, so a crafted spec or a misconfigured `group.name` cannot drop files anywhere on disk.

## What happened

Every generated file resolves to a path under `output.path`. This diagnostic fires when a resolved path lands outside that directory. Kubb treats this as a path-traversal attempt rather than a warning.

## How to fix it

- Keep generated paths within the output directory. Review the `group.name` function so it returns a plain name, not a path.
- Treat names coming from the spec as untrusted. Strip or reject `..` and path separators before using them in a file name.

## Common causes

- A `group.name` function that returns `..` segments or an absolute path.
- Operation or tag names from an untrusted spec that contain path separators or `..`.

## Example output

```txt
[KUBB_PATH_TRAVERSAL]: Resolved path "/tmp/evil.ts" is outside the output directory "/app/src/gen".
  fix: This can stem from a path traversal in the OpenAPI specification or a misconfigured `group.name` function. Keep generated paths within the output directory.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-path-traversal
```

## See also

- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
