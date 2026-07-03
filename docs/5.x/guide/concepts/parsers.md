---
layout: doc
title: Parsers - How Kubb Turns the AST into Source Code
description: Parsers are Kubb's output layer. They convert the universal AST into language-specific source code, so the same plugins can target TypeScript, Python, or any other language.
outline: deep
---

# Parsers

A parser is Kubb's output layer. It turns a [`FileNode`](/docs/5.x/guide/concepts/ast) into the source string that [storage](/docs/5.x/guide/concepts/storage) writes to disk. Because the language lives in the parser and not in the plugins, the same plugins can target TypeScript today and Python or Rust tomorrow by swapping the parser.

## Two jobs: print and parse

A parser splits the work of producing code across two moments in the build.

`print(...nodes)` runs while plugins are still generating. A plugin calls it to render language-specific AST nodes into a string, then stages that string on `FileNode.sources`. `parse(file)` runs later, after every plugin has finished, when the file processor joins the staged sources into the final output for one file. Each parser registers the file extensions it handles, and the file processor routes each emitted file to the matching parser. When no parser claims an extension, the processor joins the file's source strings directly.

## Where parsers sit in the pipeline

Parsers are the last transform before storage. The [AST](/docs/5.x/guide/concepts/ast) stays language-neutral all the way through generation, and the parser is the single place that commits to a concrete syntax. That boundary is what keeps a plugin like the React Query generator from caring whether the output is `.ts` or `.tsx`: it emits nodes, and the parser prints them.

Files reach the parser one at a time. The file processor pulls each emitted file through `parse()` and hands the result to storage without buffering the whole build, so memory stays flat no matter how many files a spec produces.

## Reference

`defineParser`, the `Parser` interface, the built-in `@kubb/parser-ts`, and a worked custom-parser example live in the [Kit API reference](/docs/5.x/reference/kit#parsers).
