---
title: 'Migration: @kubb/plugin-msw'
description: Configuration and generated-output changes for @kubb/plugin-msw when migrating from Kubb v4 to v5.
---

# Migration: `@kubb/plugin-msw`

Part of the [v4 → v5 migration guide](/docs/5.x/migration-guide). See the full option reference in [`@kubb/plugin-msw`](/plugins/plugin-msw).

`transformers.name` is replaced by [`resolver.resolveName`](/docs/5.x/migration-guide#transformersname-resolver). The `contentType` option moved to [`adapterOas`](/adapters/adapter-oas), covered in [Migration: @kubb/adapter-oas](/docs/5.x/migration-guide/adapter-oas). All other options are unchanged.

## Generated output

Handlers are now strongly typed against the request body and headers, and accept an `HttpResponseResolver` callback instead of an inline MSW handler signature.

::: code-group

```typescript [v4]
export function createUserHandler(
  data?: string | number | boolean | null | object | ((info: Parameters<Parameters<typeof http.post>[1]>[0]) => Response | Promise<Response>),
) {
  return http.post('http://localhost:3000/user', function handler(info) {
    ...
  })
}
```

```typescript [v5]
import type { HttpResponseResolver } from 'msw'
import type { CreateUserData } from '../../../models/CreateUser.ts'

export function createUserHandler(
  data?: string | number | boolean | null | object | HttpResponseResolver<Record<string, string>, CreateUserData, any>,
) {
  return http.post<Record<string, string>, CreateUserData, any>(`http://localhost:3000/user`, function handler(info) {
    ...
  })
}
```

:::
