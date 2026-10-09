
Set `throwOnErrorDefault: false` to return documented error responses as values by default. This sets the fallback on each generated request and the default `ThrowOnError` type parameter on standalone functions and SDK methods. A call with `throwOnError: true` still throws for a non-2xx response and narrows its return type to successful responses.

| | |
| --- | --- |
| Type | `boolean` |
| Required | `false` |
| Default | `true` |

```typescript
// pluginAxios({ throwOnErrorDefault: false }) or pluginFetch({ throwOnErrorDefault: false })
const result = await getPetById({ path: { petId: 1 } })
if (result.error) console.error(result.error)
```

This setting applies to the whole plugin and cannot be set in `override`. Pass `throwOnError` on a call to override it. Query hooks continue to set `throwOnError: true` explicitly.
