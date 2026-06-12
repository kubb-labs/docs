---
layout: doc
title: kubb generate
description: The generate command runs the Kubb code-generation pipeline based on your kubb.config.ts.
outline: [2, 3]
---

# `kubb generate`

Reads your [`kubb.config.ts`](/docs/5.x/reference/configuration) and runs the full code-generation pipeline. This is the default command. Running `kubb` without any arguments is equivalent to `kubb generate`.

```terminal
command: kubb generate
output:
  - ◆  Generation started
  - ◇  @kubb/plugin-ts          completed in 98ms
  - ◇  @kubb/plugin-zod         completed in 134ms
  - ◇  @kubb/plugin-react-query completed in 201ms
  - ◇  @kubb/plugin-client      completed in 77ms
  - ◇  Generation completed
  -
  -  Plugins  4 passed (4)
  -    Files  156 generated
  - Duration  1.2s
  -   Output  ./src/gen
```

## Usage

Generate using the input defined in your config:

```shell
kubb generate
```

Pass an input file to override the one in your config:

```shell
kubb generate ./petStore.yaml
```

## Arguments

| Argument  | Description                                                                                  |
| --------- | -------------------------------------------------------------------------------------------- |
| `[input]` | Optional path or URL to a Swagger/OpenAPI document. Overrides the `input` set in the config. |

## Options

| Option                                       | Default | Description                                                                                |
| -------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`               |         | Path to a specific config file (e.g. `./kubb.staging.ts`).                                 |
| `--logLevel=<silent\|info\|verbose>`, `-l`   | `info`  | Set verbosity. Use `verbose` to see plugin timing breakdowns.                             |
| `--silent`, `-s`                             | `false` | Shortcut for `--logLevel silent`. Suppresses all output.                                  |
| `--verbose`, `-v`                            | `false` | Shortcut for `--logLevel verbose`. Useful for spotting slow plugins.                      |
| `--reporter=<cli\|json\|file>`               | `cli`   | Selects which registered reporters to trigger by name, comma separated.                   |
| `--watch`, `-w`                              | `false` | Re-run the generation pipeline whenever the input spec changes.                            |
| `--no-cache`                                 | `false` | Skip the incremental build cache and regenerate everything from scratch.                  |

## Reporters

A reporter decides how a run is rendered. The config registers the available reporters with [`reporters`](/docs/5.x/reference/configuration) (the built-ins by default), and `--reporter` selects which ones to trigger by name (comma separated, like `--reporter cli,file`). Without the flag, the `cli` reporter runs. Three are built in:

| Reporter | Output                                                                          |
| -------- | ------------------------------------------------------------------------------- |
| `cli`    | The end-of-run summary in the terminal. This is the default.                    |
| `json`   | A machine-readable report on stdout (`status`, `counts`, `timings`, `diagnostics`), for CI. |
| `file`   | The run's diagnostics written to `.kubb/kubb-<name>-<timestamp>.log`.            |

Write a log file without changing anything else:

```shell
kubb generate --reporter file
```

Print a JSON report for CI and keep the exit code (non-zero on any error):

```shell
kubb generate --reporter json
```

## Examples

Run with a custom config:

```shell
kubb generate --config ./kubb.staging.ts
```

Watch the spec and regenerate on every change:

```shell
kubb generate --watch
```

Run with verbose plugin timings:

```shell
kubb generate --verbose
```

Force a full regeneration and skip the build cache:

```shell
kubb generate --no-cache
```

## See also

- [Configuration](/docs/5.x/reference/configuration): full reference for `kubb.config.ts`
- [Basic usage](/docs/5.x/getting-started/basic-usage): end-to-end walkthrough
- [Plugins](/plugins): available plugins for code generation
