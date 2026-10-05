---
layout: doc
title: Diagnostics
description: Reference for Kubb's diagnostic codes, the stable codes Kubb prints
  when a build fails, with causes and fixes.
outline:
  - 2
  - 3
order: 6
navigation:
  title: Diagnostics
  icon: i-iconoir-warning-triangle
---

# Diagnostics

When a build fails, Kubb prints a diagnostic with a stable code, the message, the location in your
document, and a suggested fix. The CLI leads with the code and lists the details below it:

```text [Terminal]
[KUBB_REF_NOT_FOUND]: Could not find a definition for #/components/schemas/Pet.
  at: #/components/schemas/Pet
  fix: Add the schema under components.schemas, or fix the $ref.
  see: https://kubb.dev/docs/5.x/reference/diagnostics#kubb-ref-not-found
```

## Severity

The severity tints the `[CODE]` tag.

| Severity | Color | Effect |
| --- | --- | --- |
| `error` | red | Fails the run with a non-zero exit code. |
| `warning` | yellow | Reported, does not fail the run. |
| `info` | blue | Advisory, does not fail the run. |

## Codes

Find the code printed by Kubb below. Each entry includes its severity and a fix.

## KUBB_ADAPTER_REQUIRED: Adapter required {#kubb-adapter-required}

Severity: `error`.

An action needs an adapter but none is configured.

Set `adapter` in your config, for example `adapterOas()`. Standard `defineConfig` supplies the default OpenAPI adapter, so this catalog code is not currently emitted for an omitted adapter.

## KUBB_BARREL_DUPLICATE_EXPORT: Duplicate barrel export {#kubb-barrel-duplicate-export}

Severity: `error`.

Two files in the same barrel directory export the same name. The barrel keeps the first export and drops the rest, so the generated code still parses, but the run is marked failed.

Rename the colliding declarations, change the resolver, or separate their output directories. A type and a value may share a name.

## KUBB_CLEAN_ROOT: Clean targets the project root {#kubb-clean-root}

Severity: `error`.

`output.clean` removes generated code before a build. Kubb stops the build instead of wiping your project when `output.path` resolves to the project root or a parent of it, which would delete `kubb.config` and every source file.

Use a generated subdirectory such as `./src/gen`. Disable `output.clean` if it contains hand-written files. Kubb rejects cleaning the project root or a parent directory.

## KUBB_DEPRECATED: Deprecated {#kubb-deprecated}

Severity: `info`.

A referenced schema or operation is marked `deprecated`.

Move away from the deprecated definition when possible. Generation continues unchanged, and the notice may recur on each run.

## KUBB_FORMAT_FAILED: Format failed {#kubb-format-failed}

Severity: `error`.

The formatter pass over the generated files failed. Formatting runs after generation. The files are written, but the run is marked failed.

Check that the formatter is installed and its config is valid. Run it against the output directory to inspect the error, or change `output.format`. Files are written, but the run fails.

## KUBB_INPUT_NOT_FOUND: Input not found {#kubb-input-not-found}

Severity: `error`.

The file set as `input` (or passed as `kubb generate PATH`) could not be read. The OpenAPI adapter checks the path before parsing, so the run stops here instead of failing later with a vague read error.

Check that the file exists and is readable. Use a path relative to `kubb.config.ts`, an absolute path, or a full URL for a remote spec.

## KUBB_INPUT_REQUEST_FAILED: Input request failed {#kubb-input-request-failed}

Severity: `error`.

A URL set as `input` answered with a 4xx or 5xx status instead of the OpenAPI document. The server was reached, so either the URL is wrong or the endpoint refused to serve the document.

Fetch the URL with `curl` and confirm it serves the OpenAPI document. For a protected document, download it and use the local file. Check server logs for a 5xx response. This also applies to remote `$ref` requests.

## KUBB_INPUT_REQUIRED: Input required {#kubb-input-required}

Severity: `error`.

An adapter is configured but no `input` was provided, so there is nothing to parse.

Set `input` to a file path, URL, inline JSON/YAML spec, or parsed document. If merging documents, provide at least one input.

## KUBB_INPUT_UNREACHABLE: Input unreachable {#kubb-input-unreachable}

Severity: `error`.

A URL set as `input` never answered, so the request failed before a status came back.

Start the server and check its host and port. Fetch the URL from the machine running Kubb. Connect to any required VPN or proxy, or use a downloaded spec. The message includes the connection failure reason.

## KUBB_INVALID_DOCUMENT: Invalid document {#kubb-invalid-document}

Severity: `error`.

The document resolved from `input` declares neither `openapi` nor `swagger`, so the adapter has nothing to read it as.

Use a document declaring `openapi` or `swagger`. Pass the document itself rather than a wrapper. Missing versions fail even when validation is disabled.

## KUBB_INVALID_PLUGIN_OPTIONS: Invalid plugin options {#kubb-invalid-plugin-options}

Severity: `error`.

A plugin was given options that cannot be honored together. The main case is `output.mode` resolving to `'file'` while a `group` option is also set, or, for `@kubb/plugin-fetch`/`@kubb/plugin-axios`, while `sdk.mode: 'tag'` is set. Both pair a single-file output with an option that only makes sense split across several files, so the build stops instead of producing a layout the options do not describe.

Single-file output cannot use `group` or `sdk.mode: 'tag'`. Remove grouping, use `sdk.mode: 'flat'`, or write to a directory. A file extension in `output.path` implies file mode unless you explicitly select directory mode.

## KUBB_INVALID_SERVER_VARIABLE: Invalid server variable {#kubb-invalid-server-variable}

Severity: `error`.

A server variable resolves to a value that its `enum` does not allow.

Choose a variable value allowed by its `enum`, correct the default, or update the enum to match the server.

## KUBB_LEGACY_INPUT: Legacy input shape {#kubb-legacy-input}

Severity: `error`.

`input` is a `{ path }` or `{ data }` wrapper. v4 used it to point at a document, and v5 takes the value directly.

Replace `input: { path: './spec.yaml' }` with `input: './spec.yaml'`, or `input: { data: spec }` with `input: spec`.

## KUBB_LINT_FAILED: Lint failed {#kubb-lint-failed}

Severity: `error`.

The linter pass over the generated files failed. Linting runs after generation. The files are written, but the run is marked failed.

Check that the linter is installed and configured. Run it manually against the output. Adjust rules for generated files or change `output.lint`. Files are written, but the run fails.

## KUBB_PATH_TRAVERSAL: Path traversal {#kubb-path-traversal}

Severity: `error`.

A resolved output path escaped the output directory. Kubb refuses to write outside `output.path`, so a crafted spec or a misconfigured `group.name` cannot drop files anywhere on disk.

Keep generated paths within `output.path` and resolver `file.path` overrides within the project root. Reject `..` and path separators in names from the spec or `group.name`.

## KUBB_PERFORMANCE: Performance {#kubb-performance}

Severity: `info`.

Records a plugin's elapsed time. Kubb collects one per plugin during a build.

This bookkeeping code is not printed as a terminal diagnostic. Run `kubb generate --verbose` to inspect plugin timings. The reported duration sums generation time and excludes config loading, formatting, linting, and post-generate hooks.

## KUBB_PLUGIN_FAILED: Plugin failed {#kubb-plugin-failed}

Severity: `error`.

A plugin threw while generating, or reported an error through `ctx.error`. The diagnostic is attributed to the plugin and fails the run.

Check the plugin options and the schema or operation named in the message. Report reproducible plugin bugs with a spec fragment. The diagnostic preserves an underlying error as its cause. For structured errors, plugin authors can use `Diagnostics.report` or `DiagnosticError`.

## KUBB_PLUGIN_INFO: Plugin info {#kubb-plugin-info}

Severity: `info`.

A plugin reported an informational message through `ctx.info`. It is advisory and does not fail the run.

No action is required. The plugin name and message appear in the summary and JSON report. Plugin authors can use `Diagnostics.report` for a stable code and source pointer.

## KUBB_PLUGIN_NOT_FOUND: Plugin not found {#kubb-plugin-not-found}

Severity: `error`.

A plugin requires another plugin that is not in the config.

Install the required plugin and add it to `plugins`, or remove its dependent plugin. Order does not matter. The adapter reads OpenAPI in v5, so do not add `@kubb/plugin-oas`.

## KUBB_PLUGIN_WARNING: Plugin warning {#kubb-plugin-warning}

Severity: `warning`.

A plugin reported a non-fatal warning through `ctx.warn`. Kubb collects and shows it, but it does not fail the run.

Read the message and adjust the input or plugin options as needed. Warnings do not fail the run. Plugin authors can use `Diagnostics.report` for a stable code and source pointer.

## KUBB_POST_GENERATE_FAILED: Post-generate command failed {#kubb-post-generate-failed}

Severity: `error`.

A post-generate command (`output.postGenerate`) exited with a non-zero status. These commands run after generation. The files are written, but the run is marked failed.

Run the command manually from the project root. Check the binary, spelling, and configuration. These commands run after formatting and linting. Files are written, but the run fails.

## KUBB_REF_NOT_FOUND: Reference not found {#kubb-ref-not-found}

Severity: `error`.

A `$ref` points at a definition that does not exist in the document.

Add the missing definition or correct the `$ref`. Run `kubb validate` before generation. Bundle documents with external references when needed.

## KUBB_UNKNOWN: Unknown error {#kubb-unknown}

Severity: `error`.

A fallback for an error that does not yet carry a specific diagnostic code.

Run `kubb generate --reporter file` for a log under `.kubb/`, or use `--verbose`. Inspect the message and stack. Report unclear failures with the message and `Environment:` block. Unclassified errors have no suggested fix or docs URL in CLI output.

## KUBB_UNSUPPORTED_FORMAT: Unsupported format {#kubb-unsupported-format}

Severity: `warning`.

A schema's `format` is not one Kubb maps to a specific type, so it falls back to the base type.

Use a supported format, omit it if the base type is sufficient, or map it through a custom parser or plugin. Generation continues using the base type.

## KUBB_UPDATE_AVAILABLE: Update available {#kubb-update-available}

Severity: `info`.

A newer Kubb version is published on npm than the one running.

Update Kubb and your project plugins through your package manager. The notice never fails a build, and the check is skipped when offline.

## Machine-readable output

`kubb generate --reporter json` prints a stable report to stdout. The output is a JSON array with
one report per config, so a single-config run still prints `[ ... ]`. CI can read diagnostics
without scraping the terminal:

```json [Report]
[
  {
    "name": "",
    "status": "failed",
    "plugins": { "passed": 2, "failed": ["plugin-zod"], "total": 3 },
    "counts": { "errors": 1, "warnings": 0, "infos": 0 },
    "filesCreated": 0,
    "durationMs": 312,
    "output": "/project/src/gen",
    "timings": [{ "plugin": "plugin-ts", "durationMs": 84 }],
    "diagnostics": [
      {
        "code": "KUBB_REF_NOT_FOUND",
        "severity": "error",
        "message": "Could not find a definition for #/components/schemas/Pet.",
        "location": { "kind": "schema", "pointer": "#/components/schemas/Pet" },
        "help": "Add the schema under components.schemas, or fix the $ref. Run `kubb validate` to check the spec.",
        "docsUrl": "https://kubb.dev/docs/5.x/reference/diagnostics#kubb-ref-not-found"
      }
    ]
  }
]
```

Each config emits one report. `counts` totals the `problem` diagnostics by severity. `timings` lists
per-plugin durations slowest first. `name` is the config name, empty when unnamed.

The exit code is unchanged: non-zero on any error. See [`--reporter`](/docs/5.x/reference/commands/generate#reporters)
for the other reporters.