---
layout: doc
title: Testing
description: kubb/kit/testing is a separate subpath for the Vitest-backed helpers used to test plugins, generators, and adapters, kept apart from kubb/kit so the authoring toolkit never pulls in Vitest.
outline: [2, 3]
---

# Testing

`kubb/kit/testing` is a separate subpath for the Vitest-backed helpers used to test plugins, generators, and adapters. It stays separate from `kubb/kit` so importing the authoring toolkit never pulls Vitest into a plugin's runtime dependencies.

```typescript twoslash [plugin.test.ts]
import { createMockedPlugin, renderGeneratorOperation, matchFiles } from 'kubb/kit/testing'
```

The subpath exports mocking builders, generator runners, and a snapshot matcher:

| Export                      | What it does                                                                                                          |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `createMockedPlugin`        | Builds a minimal plugin for a test without wiring a full config.                                                     |
| `createMockedAdapter`       | Builds a minimal adapter for a test without wiring a full config. `parse` returns an empty `InputNode` by default.   |
| `createMockedPluginDriver`  | Builds a driver around a set of plugins so a generator runs through its real lifecycle in isolation.                 |
| `renderGeneratorSchema`     | Calls a generator's `schema()` method against a `SchemaNode` fixture and collects the files it emits.                |
| `renderGeneratorOperation`  | Calls a generator's `operation()` method against an `OperationNode` fixture and collects the files it emits.         |
| `renderGeneratorOperations` | Calls a generator's `operations()` method against an array of `OperationNode` fixtures and collects the files it emits. |
| `matchFiles`                | Asserts the generated `FileNode`s match expected paths and contents through file snapshots, the assertion most generator tests end on. |
