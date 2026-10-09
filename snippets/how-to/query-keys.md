## Customize cache keys

Set `queryKey` on the plugin to change generated keys. String entries are emitted as source code, so use `JSON.stringify` for a string literal.

::tabs

:::tabs-item{label="React Query"}

```typescript [kubb.config.ts]
import { pluginReactQuery } from '@kubb/plugin-react-query'

pluginReactQuery({
  queryKey: ({ node }) => [JSON.stringify(node.operationId)],
})
```

:::

:::tabs-item{label="Vue Query"}

```typescript [kubb.config.ts]
import { pluginVueQuery } from '@kubb/plugin-vue-query'

pluginVueQuery({
  queryKey: ({ node }) => [JSON.stringify(node.operationId)],
})
```

:::

::

> [!WARNING]
> This produces a fixed key such as `['getUserByName']`, independent of arguments. Include relevant path and query parameters in the key when their values identify different resources.
