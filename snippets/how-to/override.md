Applies different plugin options to operations that match a pattern. Each entry takes the same `type` and `pattern` as `include`, plus an `options` object that accepts any plugin option except `override`, so rules cannot nest. The first matching entry merges onto the plugin defaults, and later entries do not stack.

```typescript [Type definition]
export type Override = {
  type: 'tag' | 'operationId' | 'path' | 'method' | 'contentType' | 'schemaName'
  pattern: string | RegExp
  options: Omit<Partial<Options>, 'override'>
}
```
