---
layout: doc
title: Diagnostics
description: Diagnostics is the namespace a plugin or adapter uses to build and narrow the structured errors Kubb collects during a build, each carrying a stable code, a severity, and a location.
outline: [2, 3]
---

# Diagnostics

`Diagnostics` is the namespace a plugin or adapter uses to build and narrow the structured errors Kubb collects during a build. Throw or return a `Diagnostics.Error` instead of a bare `Error` when you want a stable code, a severity, and a location attached.

| Member                  | Purpose                                                                 |
| ----------------------- | -------------------------------------------------------------------------|
| `Diagnostics.Error`     | Constructs a diagnostic-carrying error with a `code`, `severity`, and `message` |
| `Diagnostics.hasError`  | Narrows an array of diagnostics to whether any has `severity: 'error'` |
| `Diagnostics.isProblem` | Guards a diagnostic down to the problem kind (as opposed to `performance` or `update`) |

See the [Diagnostics reference](/docs/5.x/reference/diagnostics) for the full list of stable codes Kubb ships with, and how `Diagnostics.hasError` and `Diagnostics.isProblem` are used together after a build.
