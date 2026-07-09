---
layout: doc
title: Diagnostics
description: Reference for Kubb's diagnostic codes, the stable codes Kubb prints when a build fails, with causes and fixes.
outline: [2, 3]
---

# Diagnostics

When a build fails, Kubb prints a diagnostic. It carries a stable code, the message, the location in
your document, and a suggested fix. The CLI leads with the code and lists the details below it:

```text [Terminal]
[KUBB_REF_NOT_FOUND] @kubb/plugin-zod: Could not find a definition for #/components/schemas/Pet.
  at: #/components/schemas/Pet
  fix: Add the schema under components.schemas, or fix the $ref.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-ref-not-found
```

The location is a JSON pointer into the source document. Kubb parses OpenAPI into an object model, so
it points at the node (`#/components/schemas/Pet`) rather than a line and column.

Each code is stable. You can search for it and link to its page. A run collects every diagnostic
instead of stopping at the first, so one `kubb generate` surfaces every problem. The run fails only
when at least one diagnostic has `error` severity. Warnings and info never fail the build.

## Severity

The severity tints the `[CODE]` tag.

| Severity | Color | Effect |
| --- | --- | --- |
| `error` | red | Fails the run with a non-zero exit code. |
| `warning` | yellow | Reported, does not fail the run. |
| `info` | blue | Advisory, does not fail the run. |

## Input

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_INPUT_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-input-not-found) | error | The file set as `input` could not be read. |
| [`KUBB_INPUT_REQUIRED`](/docs/5.x/reference/diagnostics/kubb-input-required) | error | An adapter was configured without an `input`. |

## Configuration

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_PLUGIN_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-plugin-not-found) | error | A required plugin is missing from the config. |
| [`KUBB_ADAPTER_REQUIRED`](/docs/5.x/reference/diagnostics/kubb-adapter-required) | error | An action needs an adapter but none is configured. |
| [`KUBB_PATH_TRAVERSAL`](/docs/5.x/reference/diagnostics/kubb-path-traversal) | error | A resolved path escaped the output directory. |
| [`KUBB_INVALID_PLUGIN_OPTIONS`](/docs/5.x/reference/diagnostics/kubb-invalid-plugin-options) | error | A plugin was configured with options that cannot be honored. |

## OpenAPI

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_REF_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-ref-not-found) | error | A `$ref` could not be resolved in the document. |
| [`KUBB_INVALID_SERVER_VARIABLE`](/docs/5.x/reference/diagnostics/kubb-invalid-server-variable) | error | A server variable value is not allowed by its `enum`. |
| [`KUBB_UNSUPPORTED_FORMAT`](/docs/5.x/reference/diagnostics/kubb-unsupported-format) | warning | A schema `format` has no specific type mapping, so it falls back to the base type. |
| [`KUBB_DEPRECATED`](/docs/5.x/reference/diagnostics/kubb-deprecated) | info | A referenced schema or operation is marked `deprecated`. |

## Plugins

These carry whatever a plugin reports through its generator context (`ctx.error`, `ctx.warn`,
`ctx.info`). Each one is attributed to the plugin that reported it.

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_PLUGIN_FAILED`](/docs/5.x/reference/diagnostics/kubb-plugin-failed) | error | A plugin threw while generating, or reported an error. |
| [`KUBB_PLUGIN_WARNING`](/docs/5.x/reference/diagnostics/kubb-plugin-warning) | warning | A plugin reported a non-fatal warning. |
| [`KUBB_PLUGIN_INFO`](/docs/5.x/reference/diagnostics/kubb-plugin-info) | info | A plugin reported an informational message. |

## Output pipeline

The formatter, linter, and post-generate hooks run after generation. A failure in any of them
becomes a diagnostic and fails the run.

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_FORMAT_FAILED`](/docs/5.x/reference/diagnostics/kubb-format-failed) | error | The formatter pass over the generated files failed. |
| [`KUBB_LINT_FAILED`](/docs/5.x/reference/diagnostics/kubb-lint-failed) | error | The linter pass over the generated files failed. |
| [`KUBB_HOOK_FAILED`](/docs/5.x/reference/diagnostics/kubb-hook-failed) | error | A post-generate `hooks.done` command exited non-zero. |

## Other

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_UNKNOWN`](/docs/5.x/reference/diagnostics/kubb-unknown) | error | An error without a specific code. |

## Bookkeeping

These are not problems. They carry run metadata and never fail the build. The CLI uses them for the
summary and notices, not the diagnostic log.

| Code | Severity | Summary |
| --- | --- | --- |
| [`KUBB_PERFORMANCE`](/docs/5.x/reference/diagnostics/kubb-performance) | info | A plugin's elapsed time. The run total is the sum of these. |
| [`KUBB_UPDATE_AVAILABLE`](/docs/5.x/reference/diagnostics/kubb-update-available) | info | A newer Kubb version is available on npm. |

## Machine-readable output

`kubb generate --reporter json` prints a stable report to stdout. The output is a JSON array with
one report per config, so a single-config run still prints `[ ... ]`. CI can read diagnostics
without scraping the terminal:

```json [Report]
[
  {
    "name": "",
    "status": "failed",
    "plugins": { "passed": 2, "failed": ["@kubb/plugin-zod"], "total": 3 },
    "counts": { "errors": 1, "warnings": 0, "infos": 0 },
    "filesCreated": 0,
    "durationMs": 312,
    "output": "/project/src/gen",
    "timings": [{ "plugin": "@kubb/plugin-ts", "durationMs": 84 }],
    "diagnostics": [
      {
        "code": "KUBB_REF_NOT_FOUND",
        "severity": "error",
        "message": "Could not find a definition for #/components/schemas/Pet.",
        "location": { "kind": "schema", "pointer": "#/components/schemas/Pet" },
        "help": "Add the schema under components.schemas, or fix the $ref. Run `kubb validate` to check the spec.",
        "docsUrl": "https://kubb.dev/docs/5.x/reference/diagnostics/kubb-ref-not-found"
      }
    ]
  }
]
```

Each config emits one report. `counts` totals the `problem` diagnostics by severity. `timings` lists
per-plugin durations slowest first. `name` is the config name, empty when unnamed.

The exit code is unchanged. It is non-zero on any error. See [`--reporter`](/docs/5.x/reference/commands/generate#reporters)
for the other reporters.

## Reading a diagnostic in the terminal

The header reads `[CODE] plugin: message`. It shows the code in the severity color, then the plugin
that emitted the diagnostic when known, then the message.

`at:` holds the JSON pointer to the offending node. Config-level diagnostics such as
`KUBB_PLUGIN_NOT_FOUND` have no pointer, so they skip this line.

`fix:` is a suggested fix. `see:` links to the page for that code.

At `--logLevel silent` Kubb suppresses the diagnostic log. The run still fails with a non-zero exit
code, so CI keeps working without the noise.
