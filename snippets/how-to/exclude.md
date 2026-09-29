Skips any operation or schema that matches at least one entry, the opposite of `include`. Entries use the same `type` and `pattern` fields as `include`, and when both options match an item, `exclude` wins.

When operations are excluded on a client plugin (`@kubb/plugin-fetch` or `@kubb/plugin-axios`), dependent plugins (`@kubb/plugin-react-query`, `@kubb/plugin-vue-query`, `@kubb/plugin-swr`, `@kubb/plugin-mcp`) skip generating hooks or handlers for those operations automatically, without requiring duplicate `exclude` configurations.
