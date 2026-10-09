Switch the mode to see where these operations land on disk.

::grouping-diagram
::

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'`.

> [!IMPORTANT]
> Combining `group` with `output.mode: 'file'` stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.

#### group.type

Property used to assign each operation to a group (`'tag' | 'path'`), required whenever `group` is set. An operation with no tag goes in the `default` group.

::field-group

:::field{name="'tag'"}
Uses the operation's first tag.
:::

:::field{name="'path'"}
Uses the first URL segment, such as `pet` for `/pet/{petId}`.
:::

::
