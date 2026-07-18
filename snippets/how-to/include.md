Generates only the operations and schemas that match at least one entry, and skips the rest. Each entry filters by `tag`, `operationId`, `path`, `method`, `contentType`, or `schemaName`, with a `pattern` that can be a string or a `RegExp`, both matched as a regular expression against the value. A string pattern is compiled with `new RegExp(pattern)`, so it is not an exact match: `pattern: 'pet'` also matches `'petType'` or `'superpet'`.

```typescript [Type definition]
export type Include = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
}
```
