---
layout: doc
title: kubb generate
description: The generate command runs the Kubb code-generation pipeline based on your kubb.config.ts.
outline: [2, 3]
---

# `kubb generate`

Run `kubb generate` to read your [`kubb.config.ts`](/docs/5.x/reference/configuration) and run the code-generation pipeline. This is the default command. Run `kubb` with no arguments and it runs `kubb generate`.

```terminal
command: kubb generate
output:
  - ◆  Generation started
  - ◇  @kubb/plugin-ts          completed in 98ms
  - ◇  @kubb/plugin-zod         completed in 134ms
  - ◇  @kubb/plugin-react-query completed in 201ms
  - ◇  @kubb/plugin-axios       completed in 77ms
  - ◇  Generation completed
  -
  -  Plugins  4 passed (4)
  -    Files  156 generated
  - Duration  1.2s
  -   Output  ./src/gen
```

## Usage

Generate from the input set in your config:

```shell [Terminal]
kubb generate
```

Pass an input file to override the config:

```shell [Terminal]
kubb generate ./petStore.yaml
```

## Arguments

| Argument  | Description                                                                                  |
| --------- | -------------------------------------------------------------------------------------------- |
| `[input]` | Optional path or URL to a Swagger/OpenAPI document. Overrides the `input` set in the config. |

## Options

| Option                                       | Default | Description                                                                |
| -------------------------------------------- | ------- | ------------------------------------------------------------------------- |
| `--config=<path>`, `-c <path>`               |         | Path to a config file, such as `./kubb.staging.ts`.                       |
| `--logLevel=<silent\|info\|verbose>`, `-l`   | `info`  | Set the verbosity. Use `verbose` to see plugin timings.                   |
| `--silent`, `-s`                             | `false` | Force `logLevel` to `silent`. Suppresses output.                          |
| `--verbose`, `-v`                            | `false` | Force `logLevel` to `verbose`. Shows slow plugins.                        |
| `--reporter=<cli\|json\|file>`               |         | Pick which reporters to trigger, comma separated. Defaults to `cli`.      |
| `--watch`, `-w`                              | `false` | Re-run the pipeline whenever the input spec changes.                      |

`--reporter` takes no short flag.

## Reporters

A reporter decides how a run is rendered. The config registers the available reporters with [`reporters`](/docs/5.x/reference/configuration), and `--reporter` picks which ones to trigger by name (comma separated, like `--reporter cli,file`). Without the flag, the `cli` reporter runs. Three ship out of the box.

| Reporter | Output                                                                          |
| -------- | ------------------------------------------------------------------------------- |
| `cli`    | The end-of-run summary in the terminal. This runs when you pass no flag.        |
| `json`   | A machine-readable report on stdout (`status`, `counts`, `timings`, `diagnostics`) for CI. |
| `file`   | The run's diagnostics, written to `.kubb/kubb-<name>-<timestamp>.log`.          |

Write a log file:

```shell [Terminal]
kubb generate --reporter file
```

Print a JSON report for CI. The exit code is non-zero on any error:

```shell [Terminal]
kubb generate --reporter json
```

## Examples

Run with a custom config:

```shell [Terminal]
kubb generate --config ./kubb.staging.ts
```

Watch the spec and regenerate on every change:

```shell [Terminal]
kubb generate --watch
```

Run with verbose plugin timings:

```shell [Terminal]
kubb generate --verbose
```

## See also

- [Configuration](/docs/5.x/reference/configuration): full reference for `kubb.config.ts`
- [Basic usage](/docs/5.x/getting-started/basic-usage): end-to-end walkthrough
- [Plugins](/plugins): available plugins for code generation
