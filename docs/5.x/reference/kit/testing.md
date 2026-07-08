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

`createMockedPlugin` and `createMockedAdapter` build a minimal plugin or adapter for a test without wiring a full config. `createMockedPluginDriver` builds a driver around a set of plugins so a generator can run through its real lifecycle in isolation. `renderGeneratorSchema`, `renderGeneratorOperation`, and `renderGeneratorOperations` call a generator's `schema()`, `operation()`, or `operations()` method directly against a node fixture and return the resulting files. `matchFiles` asserts a set of generated `FileNode`s matches expected paths and contents, the assertion most generator tests end on.
