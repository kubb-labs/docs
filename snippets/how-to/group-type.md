Property used to assign each operation to a group (`'tag' | 'path'`), required whenever `group` is set. An operation with no tag goes in the `default` group.

- `'tag'` uses the operation's first tag.
- `'path'` uses the first URL segment, such as `pet` for `/pet/{petId}`.
