---
layout: doc
title: LLMS.txt - AI
description: Kubb publishes llms.txt and llms-full.txt so LLMs can consume the full documentation in a single request. Learn how to point your AI assistant at these files.
outline: [2, 3]
---

# LLMS.txt

Kubb generates an `llms.txt` file at build time. It follows the [llms.txt standard](https://llmstxt.org/).
The file gives LLMs a compact, machine-readable index of the whole documentation. With it, they
answer questions about Kubb without inventing outdated or missing details.

The sections below list the available files and show how to point an AI assistant at them.

## Available files

| URL                                                                | Description                                           |
| ------------------------------------------------------------------ | ----------------------------------------------------- |
| [`https://kubb.dev/llms.txt`](https://kubb.dev/llms.txt)           | Table of contents with one-line descriptions per page |
| [`https://kubb.dev/llms-full.txt`](https://kubb.dev/llms-full.txt) | Complete documentation in a single file               |

## Using llms.txt in your AI assistant

Most chat interfaces let you attach a URL or paste text. Use the full file when you need complete
documentation coverage:

```text [Prompt]
Read https://kubb.dev/llms-full.txt and answer questions about Kubb.
```

For models with a small context window, use the index file and ask the assistant to fetch
individual pages on demand:

```text [Prompt]
Use https://kubb.dev/llms.txt to find relevant pages, then read them.
```

## See also

- [llms.txt standard](https://llmstxt.org/): specification for LLM-friendly documentation
- [MCP](/docs/5.x/ai/mcp): connect AI editors directly to Kubb's MCP server
