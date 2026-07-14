Switch the mode to see where these operations land on disk.

<GroupingDiagram />

Splits generated files into subfolders by the operation's tag or URL path, each under `{output.path}/{groupName}/`. Without `group`, every file lands directly in `output.path`. It applies only to `output.mode: 'directory'`.

> [!IMPORTANT]
> Combining `group` with `output.mode: 'file'` stops the build with a `KUBB_INVALID_PLUGIN_OPTIONS` error.
