A spec with hundreds of operations produces hundreds of files by default, one per operation.

Set `output.mode: 'file'` to write everything this plugin generates into a single file at `output.path` instead. This is the option that actually cuts the file count, at the cost of losing per-operation splitting. It can't be combined with `group`.

`group: { type: 'tag' }` (or `{ type: 'path' }`) is a different tool for a different problem: it keeps one file per operation but nests them under per-tag or per-path subfolders, so a large `output.mode: 'directory'` tree stays navigable. The file count is unchanged.

For plugins that emit hook or composable variants, such as `plugin-react-query` and `plugin-vue-query`, only enable an option like `suspense` or `infinite` when you use it. Each variant adds a file per matching operation.
