---
layout: doc
title: kubb validate
description: The validate command checks that a Swagger/OpenAPI document is valid without running the full pipeline.
outline: [2, 3]
---

# `kubb validate`

Checks that your Swagger/OpenAPI document is valid without running the full code-generation pipeline. Use it to catch syntax errors early in CI or before committing a spec change.

```terminal
command: kubb validate -i ./petStore.yaml
output:
  - ✅ Validation success
```

> [!IMPORTANT]
> `@kubb/adapter-oas` is an optional peer dependency. Install it before running this command:
>
> ```shell
> npm i @kubb/adapter-oas
> ```

## Usage

Validate a local OpenAPI file:

```shell
kubb validate -i ./petStore.yaml
```

Validate a remote document:

```shell
kubb validate -i https://petstore3.swagger.io/api/v3/openapi.json
```

## Options

| Option                        | Default | Required | Description                                              |
| ----------------------------- | ------- | -------- | -------------------------------------------------------- |
| `--input=<path>`, `-i <path>` |         | `true`   | Path or URL to the Swagger/OpenAPI document to validate. |

## Examples

Validate a local file:

```shell
kubb validate -i ./petStore.yaml
```

Validate a remote spec in CI:

```shell
kubb validate -i https://petstore3.swagger.io/api/v3/openapi.json
```

> [!TIP]
> `kubb validate` exits with a non-zero status code on failure, so you can use it as a pre-commit hook or CI step to fail the build when the spec is invalid.

## See also

- [Adapters](/adapters): OAS adapter that parses the validated spec
- [Basic usage](/docs/5.x/getting-started/basic-usage): end-to-end walkthrough
