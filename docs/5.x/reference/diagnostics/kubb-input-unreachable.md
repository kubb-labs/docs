---
layout: doc
title: KUBB_INPUT_UNREACHABLE
description: The KUBB_INPUT_UNREACHABLE diagnostic fires when a URL set as input never answers, so the request fails before a status comes back.
outline: [2, 3]
---

# KUBB_INPUT_UNREACHABLE: Input unreachable

Code: `KUBB_INPUT_UNREACHABLE`
Level: error

A URL set as `input` never answered, so the request failed before a status came back.

## What happened

When `input` is a URL, Kubb fetches it before parsing. This diagnostic covers every failure that happens before the server answers: a refused connection, an unknown host, an untrusted certificate, and a timeout. The message carries the reason, such as `connect ECONNREFUSED 127.0.0.1:8000`, which the runtime otherwise hides behind a bare `fetch failed`.

Once a server does answer, a 4xx or 5xx status reports [`KUBB_INPUT_REQUEST_FAILED`](/docs/5.x/reference/diagnostics/kubb-input-request-failed) instead.

## Common causes

- The API server is not running, or it listens on a different port than the one in `input`.
- A typo in the host name, or a host that only resolves over a VPN.
- A proxy or firewall drops the connection before it reaches the host.

## How to fix it

- Start the server, and check that the port in `input` matches the one it listens on.
- Fetch the URL with `curl` from the machine running Kubb.
- For a host behind a VPN or proxy, connect first, or download the document and point `input` at the local file.

## Example output

```text [Terminal]
[KUBB_INPUT_UNREACHABLE]: Cannot reach http://localhost:8000/api/schema/: connect ECONNREFUSED 127.0.0.1:8000
  fix: Check that the host is running and reachable from this machine. For a local server, start it and confirm the port matches the one in `input`.
  see: https://kubb.dev/docs/5.x/reference/diagnostics/kubb-input-unreachable
```

## See also

- [`KUBB_INPUT_REQUEST_FAILED`](/docs/5.x/reference/diagnostics/kubb-input-request-failed)
- [`KUBB_INPUT_NOT_FOUND`](/docs/5.x/reference/diagnostics/kubb-input-not-found)
- [Configuration](/docs/5.x/reference/configuration)
- [Diagnostics reference](/docs/5.x/reference/diagnostics)
