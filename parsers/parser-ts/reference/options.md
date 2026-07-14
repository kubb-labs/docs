---
layout: doc
title: Options
description: Configuration options for @kubb/parser-ts. Rewrite the import and export extensions the TypeScript parser emits.
outline: deep
---

# Options

`parserTs` and `parserTsx` accept the same single option.

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| [`extension`](#extension) | `Record<string, string>` | `{ '.ts': '' }` | Rewrite the extensions emitted in `import`/`export` statements |

### extension

Rewrites the extensions emitted in `import`/`export` statements. Keys are the source extension, values the output, and `''` drops it. Only the module-specifier string changes, never the on-disk filename.

Use it to emit `.js` imports from `.ts` sources for an ESM dual package, or to keep the source extension for Node16/NodeNext resolution.

|          |                          |
| -------: | :----------------------- |
|    Type: | `Record<string, string>` |
| Default: | `{ '.ts': '' }`          |

```typescript
parserTs({ extension: { '.ts': '.js' } })  // import './api.js' instead of './api'
parserTs({ extension: { '.ts': '.ts' } })  // import './api.ts' instead of './api'
```
