---
layout: doc
title: Adapters - How Kubb Reads Any Specification
description: An adapter is the only part of Kubb that understands the input format. It converts a spec like OpenAPI into the universal AST, so every plugin works regardless of the source.
outline: deep
---

# Adapters

An adapter is the front door of the pipeline. It reads your specification and converts it into the universal [AST](/docs/5.x/guide/concepts/ast). Everything downstream, every [plugin](/docs/5.x/guide/concepts/plugins) and [parser](/docs/5.x/guide/concepts/parsers), works off that AST and never touches the original spec. The adapter is the one place that knows whether the input was OpenAPI, AsyncAPI, or something you invented.

<FlowDiagram preset="adapter" />

## Why adapters exist

Without this boundary, every plugin would need its own OpenAPI reader, and adding a new input format would mean rewriting all of them. The adapter pulls that knowledge into a single layer, so writing one adapter for a format lets the entire plugin ecosystem work on top of it unchanged. That is what lets Kubb target OpenAPI today and AsyncAPI or a GraphQL schema tomorrow without touching the generators.

Kubb ships [`@kubb/adapter-oas`](/adapters/adapter-oas/) for OpenAPI 2.0, 3.0, and 3.1, and picks it for you when you import `defineConfig` from the `kubb` package. You write a custom adapter only when your source is a format Kubb does not parse yet.
