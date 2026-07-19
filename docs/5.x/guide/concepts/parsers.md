---
layout: doc
title: Parsers - How Kubb Turns the AST into Source Code
description: Parsers are Kubb's output layer. They convert the universal AST into language-specific source code, so the same plugins can target TypeScript, Python, or any other language.
outline: deep
---

# Parsers

A parser is Kubb's output layer. It turns the language-neutral [AST](/docs/5.x/guide/concepts/ast) a plugin emits into the source string that [storage](/docs/5.x/guide/concepts/storage) writes to disk. The language lives in the parser, not in the plugins, so the same plugins target TypeScript today and Python or Rust tomorrow. You swap the parser, not the plugins.

<FlowDiagram preset="parsers" />

## Why the language lives here

The AST stays language-neutral the whole way through generation. The parser is the one place that commits to a concrete syntax, which is why a plugin like React Query never cares whether its output is `.ts` or `.tsx`: it emits nodes, and the parser decides how they read as code.

A parser claims a set of file extensions, and Kubb hands each generated file to the parser that owns its extension. That is how a single build writes `.ts` through the TypeScript parser and `.md` through the Markdown parser without either one knowing about the other.

## Two jobs: print and parse

A parser works at two moments in a build:

- `print` runs while plugins are still generating. It turns their nodes into strings.
- `parse` runs once at the end. It joins those strings into the finished file.

Doing the join last is what lets a large spec generate file by file instead of holding the whole output in memory. For the `print` and `parse` signatures, the `Parser` interface, and a walkthrough of writing your own, see the [parser reference](/docs/5.x/reference/kit/parsers).
