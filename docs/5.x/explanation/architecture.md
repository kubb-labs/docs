---
layout: doc
title: Architecture
description: Understand how Kubb converts API specifications into generated
  files through adapters, the AST, plugins, parsers, and storage.
outline:
  - 2
  - 3
order: 1
---

# Architecture

Kubb separates the input specification, generated content, output syntax, and destination. Each layer has one job:

| Layer | Responsibility |
| --- | --- |
| Adapter | Read the specification and produce an `InputNode`. |
| AST | Describe schemas and operations in a shared tree. |
| Plugin | Run generators that emit `FileNode`s. |
| Parser | Convert emitted nodes into source code. |
| Storage | Persist the generated files. |

::architecture-pipeline

## Configuration

`defineConfig` from `kubb/config` supplies the OpenAPI adapter, TypeScript/TSX/Markdown parsers, filesystem storage, and a barrel plugin. Barrel generation follows `output.barrel` at the root or on individual plugins.

Choose the outputs with `plugins`. Configure the destination with `output.path`. The [configuration reference](/docs/5.x/reference/configuration) lists the available fields and defaults.

## Adapters {#adapters}

An adapter resolves input-specific details, including references, nullability, discriminators, and formats. The default [OpenAPI adapter](/adapters/adapter-oas/) supports OpenAPI 2.0, 3.0, and 3.1. A custom adapter converts another input format into the same AST, so downstream plugins do not read that format directly.

::flow-diagram{preset="adapter"}

## AST {#ast}

An `InputNode` contains reusable schemas and operations. Operations connect parameters, request bodies, and responses to schema nodes. Request bodies and responses have one `ContentNode` per content type.

::ast-tree

Nodes carry a `kind` discriminant. Schemas also carry a `type` discriminant. The `transform` visitor rewrites nodes, while `collect` gathers matching nodes. Import the `ast` namespace from `kubb/kit`. See [AST reference](/docs/5.x/reference/kit/ast) for node builders, visitors, and guards.

## Plugins and generators {#plugins}

Each plugin owns an output: types, clients, hooks, validators, mocks, or custom files. Its generators handle individual schemas, individual operations, or the complete operation set.

Macros transform AST nodes before generators use them. They run per plugin, so one plugin's transformations do not modify another plugin's input. Resolvers keep names and paths consistent across generated files.

See [Extension model](/docs/5.x/explanation/extensions) for how these pieces cooperate.

## Parsers {#parsers}

Each parser claims file extensions. Kubb selects it for the emitted file, prints nodes during generation, and assembles the final source through `parse`. The default parsers handle `.ts`, `.tsx`, and `.md`.

A printer inside a generator handles schema-specific output. A parser handles the assembled file. See [Customize printers](/docs/5.x/how-to/printers) and [Parser reference](/docs/5.x/reference/kit/parsers).

## Storage {#storage}

Storage separates generation from its destination. `fsStorage()` writes to disk. `memoryStorage()` keeps results in a `Map`. Kubb skips writes when the stored content already matches.

A custom driver implements the [Storage interface](/docs/5.x/reference/kit/storage#storage-interface) to target another backend. Formatting, linting, and CLI post-generation commands follow generation.

## See also

- [Extension model](/docs/5.x/explanation/extensions)
- [Quickstart](/docs/5.x/tutorials/quickstart)
- [Kit API](/docs/5.x/reference/kit)
