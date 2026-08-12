---
layout: doc
title: KUBB_INPUT_REQUEST_FAILED
description: The KUBB_INPUT_REQUEST_FAILED diagnostic fires when a URL set as input answers with a 4xx or 5xx status instead of the OpenAPI document.
outline: [2, 3]
---

# KUBB_INPUT_REQUEST_FAILED: Input request failed

Code: `KUBB_INPUT_REQUEST_FAILED`
Level: error

A URL set as `input` answered with a 4xx or 5xx status instead of the OpenAPI document. The server was reached, so the URL is wrong or the endpoint refused to serve the document.

## What happened

When `input` is a URL, Kubb fetches it before parsing. Any response outside the 2xx range stops the run here, with the status in the message. The same check covers URLs reached through a `$ref`, so a document that pulls a remote schema reports the URL that failed rather than the one you configured.

## Common causes

- The path is wrong. A server often serves its UI at `/api/schema/` and the document itself at a different path or behind a query parameter.
- The endpoint needs authentication. Kubb sends no credentials, so a protected spec answers 401 or 403.
- The server is failing. A 5xx means the document exists but the server could not serve it.

## How to fix it

- Open the URL in a browser or with `curl` and confirm it returns the OpenAPI document, not an HTML page or an error.
- For a spec behind authentication, download it once and point `input` at the local file.
- For a 5xx, check the server logs, then run Kubb again.

## Example output

```text [Terminal]
[KUBB_INPUT_REQUEST_FAILED]: The server at http://localhost:8000/api/schema/ answered with HTTP 404 Not Found instead of the OpenAPI document.
  fix: Check the URL. Open it in a browser or with `curl` to confirm it serves the OpenAPI document.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-request-failed
```

## See also

- [`KUBB_INPUT_UNREACHABLE`](/docs/5.x/reference/diagnostics/kubb-input-unreachable)
- [`KUBB_INPUT_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-input-not-found)
- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
