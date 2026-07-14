Generates only the operations and schemas that match at least one entry, and skips the rest. Each entry filters by `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`, with a `pattern` that is a string (exact) or a `RegExp` (fuzzy).

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```
