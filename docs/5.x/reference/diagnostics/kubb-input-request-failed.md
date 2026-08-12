---
layout: doc
title: KUBB_INPUT_REQUEST_FAILED
description: The KUBB_INPUT_REQUEST_FAILED diagnostic fires when a URL set as input answers with a 4xx or 5xx status instead of the OpenAPI document.
outline: [2, 3]
---

# KUBB_INPUT_REQUEST_FAILED: Input request failed

Code: `KUBB_INPUT_REQUEST_FAILED`
Level: error

A URL set as `input` answered with a 4xx or 5xx status instead of the OpenAPI document. The server was reached, so either the URL is wrong or the endpoint refused to serve the document.

## What happened

When `input` is a URL, Kubb fetches it before parsing. Any response outside the 2xx range stops the run, with the status in the message. URLs reached through a `$ref` go through the same check, so a document that pulls in a remote schema names the URL that actually failed, not the one you configured.

## Common causes

- The URL points at the API's documentation UI rather than the document itself.
- The endpoint needs credentials. Kubb sends none, so a protected document answers 401 or 403.
- The server broke while building the document, which is what a 5xx means here.

## How to fix it

- Open the URL in a browser or with `curl` and check that you get the document back, not an HTML page.
- For a document behind authentication, download it once and point `input` at the local file.
- For a 5xx, check the server logs.

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
