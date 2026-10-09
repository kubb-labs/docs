---
layout: doc
title: Options
description: Configuration options for @kubb/plugin-redoc.
outline: deep
---

# Options

::field-group

:::field{name="output" type="{ path: string }"}
Where the generated HTML file is written. [See details](#output).

Default: `{ path: 'docs.html' }`.
:::

::

### output

Where the generated Redoc HTML file is written.

Type: `{ path: string }`. Default: `{ path: 'docs.html' }`.

#### output.path

File path of the generated HTML, resolved against the global `output.path`. Unlike most plugins, this points at a single file, not a directory.

End the path with a `.html` extension. If you leave the extension off, Kubb still writes the file and uses the path as the plugin output name.

Type: `string`. Default: `'docs.html'`.

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
