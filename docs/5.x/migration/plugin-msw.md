---
title: 'Migration: @kubb/plugin-msw'
description: Configuration and generated-output changes for @kubb/plugin-msw when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-msw`

Part of the [v4 → v5 migration guide](/docs/5.x/migration). For the full option reference, see [`@kubb/plugin-msw`](/plugins/plugin-msw/).

[`resolver.name`](/docs/5.x/migration#transformersname-resolver) replaces `transformers.name`. The `contentType` option moved to [`adapterOas`](/adapters/adapter-oas/), covered in [Migration: @kubb/adapter-oas](/docs/5.x/migration/adapter-oas), and the `generators` option is [gone](/docs/5.x/migration#generators-removed). The `parser` (`'data' | 'faker'`, default `'data'`), `handlers`, and `baseURL` options carry over unchanged.

## Generated output

Handlers are now typed against the request body and headers. They take an `HttpResponseResolver` callback in place of an inline MSW handler signature.

```diff [Generated output]
+import type { HttpResponseResolver } from 'msw'
+import type { CreateUserBody } from '../../../models/CreateUser.ts'

export function createUserHandler(
-  data?: string | number | boolean | null | object | ((info: Parameters<Parameters<typeof http.post>[1]>[0]) => Response | Promise<Response>),
+  data?: string | number | boolean | null | object | HttpResponseResolver<Record<string, string>, CreateUserBody, any>,
) {
-  return http.post('http://localhost:3000/user', function handler(info) {
+  return http.post<Record<string, string>, CreateUserBody, any>(`http://localhost:3000/user`, function handler(info) {
    ...
  })
}
```
