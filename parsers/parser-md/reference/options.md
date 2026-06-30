---
layout: doc
title: Options
description: Configuration reference for @kubb/parser-md.
outline: deep
---

# Options

`@kubb/parser-md` takes no options of its own. To add a YAML frontmatter block, set `frontmatter` on a file's `meta` inside a plugin. The parser then prepends it to the output. Any serializable key-value object works.

|           |                                   |
| --------: | :-------------------------------- |
|     Type: | `Record<string, unknown> \| null` |
| Required: | `false`                           |

```typescript [plugin example]
ast.factory.createFile({
  baseName: 'README.md',
  path: `${config.output.path}/README.md`,
  meta: {
    frontmatter: { title: 'API Reference', layout: 'doc' },
  },
  sources: [...],
})
```
