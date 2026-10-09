---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-redoc.
outline: deep
---

# Options

`pluginRedoc()` accepts a single option, the path of the HTML file it writes. It takes none of the [shared plugin options](/docs/5.x/reference/plugin-options).

## Options overview

| Option | Purpose | Default |
| --- | --- | --- |
| [`output`](#output) | Where the generated HTML file is written. | `{ path: 'docs.html' }` |
| ↳ [`output.path`](#output-path) | Choose the generated HTML file path. | `'docs.html'` |

## Option details

### output

Where the generated Redoc HTML file is written.

| | |
| --- | --- |
| Type | `{ path: string }` |
| Required | `false` |
| Default | `{ path: 'docs.html' }` |

#### output.path

File path of the generated HTML, resolved against the global `output.path`. Unlike most plugins, this points at a single file, not a directory. End the path with `.html`. If you leave the extension off, Kubb still writes the file and uses the path as the plugin output name.

| | |
| --- | --- |
| Type | `string` |
| Required | `false` |
| Default | `'docs.html'` |

With `output.path` set to `'docs.html'` and the global `output.path` set to `'./src/gen'`, the plugin writes one file:

::file-tree
---
tree:
  - name: src
    type: dir
    children:
      - name: gen
        type: dir
        children:
          - name: docs.html
---
::
