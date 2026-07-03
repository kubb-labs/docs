---
layout: doc
title: kubb validate
description: The validate command checks that a Swagger/OpenAPI document is valid without running the full pipeline.
outline: [2, 3]
---

# `kubb validate`

Run `kubb validate` to check that a Swagger/OpenAPI document is valid without running the pipeline. Use it to catch errors early in CI or before you commit a spec change.

```terminal
command: kubb validate -i ./petStore.yaml
output:
  - ✅ Validation success
```

> [!IMPORTANT]
> `@kubb/adapter-oas` is an optional dependency. Install it before you run this command:
>
> ```shell [Terminal]
> npm i @kubb/adapter-oas@beta
> ```

## Usage

Validate a local OpenAPI file:

```shell [Terminal]
kubb validate -i ./petStore.yaml
```

Validate a remote document:

```shell [Terminal]
kubb validate -i https://petstore3.swagger.io/api/v3/openapi.json
```

## Options

| Option                        | Default | Required | Description                                              |
| ----------------------------- | ------- | -------- | -------------------------------------------------------- |
| `--input=<path>`, `-i <path>` |         | `true`   | Path or URL to the Swagger/OpenAPI document to validate. |

> [!TIP]
> `kubb validate` exits with a non-zero status code when the spec is invalid. Use it as a pre-commit hook or CI step to fail the build.

## See also

- [Adapters](/adapters): OAS adapter that parses the validated spec
- [Basic usage](/docs/5.x/getting-started/basic-usage): end-to-end walkthrough
