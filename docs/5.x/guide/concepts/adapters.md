---
layout: doc
title: Adapters - How Kubb Reads Any Specification
description: An adapter is the only part of Kubb that understands the input format. It converts a spec like OpenAPI into the universal AST, so every plugin works regardless of the source.
outline: deep
---

# Adapters

An adapter is the front door of the pipeline. It reads your specification and converts it into the universal [AST](/docs/5.x/guide/concepts/ast). Everything downstream, every [plugin](/docs/5.x/guide/concepts/plugins) and [parser](/docs/5.x/guide/concepts/parsers), works off that AST and never touches the original spec. The adapter is the one place that knows whether the input was OpenAPI, AsyncAPI, or something you invented.

## Why adapters exist

Without this boundary, every plugin would need its own OpenAPI reader, and adding a new input format would mean rewriting all of them. The adapter pulls that knowledge into a single layer. Write one adapter for a format and the entire plugin ecosystem works on top of it unchanged. That is what lets Kubb target OpenAPI today and AsyncAPI or a GraphQL schema tomorrow without touching the generators.

Kubb ships [`@kubb/adapter-oas`](/adapters/adapter-oas) for OpenAPI 2.0, 3.0, and 3.1, and picks it for you when you import `defineConfig` from the `kubb` package. You write a custom adapter only when your source is a format Kubb does not parse yet.

## Dialects keep the format-specific part small

Most of an adapter's work, turning schema objects into AST nodes, is generic JSON Schema and is shared across adapters. Only a handful of decisions actually differ between specs, such as how each one marks a field nullable or describes a discriminator. Kubb isolates those decisions behind a dialect: a single object the shared converters read so they never hard-code OpenAPI assumptions. A new adapter supplies its own dialect and reuses everything else, which keeps the format-specific surface small enough to test by swapping that one object.

## Reference

`createAdapter`, the `Adapter` interface, streaming, the OpenAPI adapter options, and a worked custom-adapter example live in the [Adapters API reference](/docs/5.x/reference/adapters).
