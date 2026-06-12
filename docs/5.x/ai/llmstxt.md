---
layout: doc
title: LLMS.txt - AI
description: Kubb publishes llms.txt and llms-full.txt so LLMs can consume the full documentation in a single request. Learn how to point your AI assistant at these files.
outline: [2, 3]
---

# LLMS.txt

Kubb generates an `llms.txt` file at build time following the [llms.txt standard](https://llmstxt.org/). This gives LLMs a compact, machine-readable index of the entire documentation so they can answer questions about Kubb without hallucinating outdated or missing details.

## Available files

| URL                                                                | Description                                           |
| ------------------------------------------------------------------ | ----------------------------------------------------- |
| [`https://kubb.dev/llms.txt`](https://kubb.dev/llms.txt)           | Table of contents with one-line descriptions per page |
| [`https://kubb.dev/llms-full.txt`](https://kubb.dev/llms-full.txt) | Complete documentation in a single file               |

## Using llms.txt in your AI assistant

Most chat interfaces let you attach a URL or paste text directly. Use the full file when you need complete documentation coverage:

```
Read https://kubb.dev/llms-full.txt and answer questions about Kubb.
```

For context-window-constrained models, use the index file and ask the assistant to fetch individual pages on demand:

```
Use https://kubb.dev/llms.txt to find relevant pages, then read them.
```

## See also

- [llms.txt standard](https://llmstxt.org/): specification for LLM-friendly documentation
- [MCP](/docs/5.x/ai/mcp): connect AI editors directly to Kubb's MCP server
- [Skills](/docs/5.x/ai/skills): AI coding skills for working with Kubb
