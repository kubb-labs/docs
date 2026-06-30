---
layout: doc
title: Options
description: All configuration options for @kubb/plugin-redoc.
outline: deep
---

# Options

### output

Where the generated Redoc HTML file is written. The path is resolved against the global `output.path` on `defineConfig`.

|           |                         |
| --------: | :---------------------- |
|     Type: | `{ path: string }`      |
| Required: | `false`                 |
|  Default: | `{ path: 'docs.html' }` |

#### output.path

File path of the generated HTML, resolved against the global `output.path`. Unlike most plugins, this points at a single file, not a directory.

End the path with a `.html` extension. If you leave the extension off, Kubb still writes the file and uses the path as the plugin output name.

|           |               |
| --------: | :------------ |
|     Type: | `string`      |
| Required: | `true`        |
|  Default: | `'docs.html'` |

With `output.path` set to `'docs.html'` and the global `output.path` set to `'./src/gen'`, the plugin writes one file:

```text [Resulting tree]
src/
└── gen/
    └── docs.html
```

