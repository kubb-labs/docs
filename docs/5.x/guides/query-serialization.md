---
layout: doc

title: Query serialization in Kubb - control how query params reach the URL
description: Shape the query string the generated client builds. Pick an array or object style with explode, allow reserved characters, or pass your own serializer, for Fetch and Axios.
outline: deep
---

# Query serialization

The client Kubb generates turns the `query` you pass into a search string before the request leaves your app. The default covers the common OpenAPI shapes, and a `querySerializer` option lets you change the style per array and object, keep reserved characters intact, or replace the whole step with your own function.

Both client plugins share the same option, so this guide applies to [`@kubb/plugin-fetch`](/plugins/plugin-fetch) and [`@kubb/plugin-axios`](/plugins/plugin-axios).

## The default

Without any configuration the serializer follows the OpenAPI 3.x defaults:

- Arrays explode into repeated keys: `{ tags: ['a', 'b'] }` becomes `tags=a&tags=b`.
- Nested objects use the `deepObject` style: `{ filter: { name: 'odie' } }` becomes `filter[name]=odie`.
- Reserved characters are percent-encoded, and `undefined`, `null`, and empty arrays are dropped.

This matches what most servers expect, so most apps never set the option. The examples here show the readable form. On the wire the reserved characters encode, so `filter[name]=odie` is sent as `filter%5Bname%5D=odie`.

## Declarative options

When a server wants a different shape, pass an options object instead of a function. Kubb builds the serializer for you:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  querySerializer: {
    array: { style: 'pipeDelimited', explode: false },
    object: { style: 'deepObject', explode: true },
    allowReserved: false,
  },
})
```

The shape mirrors the OpenAPI query parameter model:

```typescript
type QuerySerializerOptions = {
  array?: { style: 'form' | 'spaceDelimited' | 'pipeDelimited'; explode: boolean }
  object?: { style: 'form' | 'deepObject'; explode: boolean }
  allowReserved?: boolean
}
```

### Array styles

The `array` knob decides how a list of values joins together. With `explode` on, each value repeats under the same key. With it off, the values join with the delimiter the style names.

| `style` | `explode` | `{ tags: ['a', 'b'] }` |
| --- | --- | --- |
| `form` | `true` | `tags=a&tags=b` |
| `form` | `false` | `tags=a,b` |
| `spaceDelimited` | `false` | `tags=a%20b` |
| `pipeDelimited` | `false` | `tags=a\|b` |

### Object styles

The `object` knob decides how a nested object spreads across the query. The `deepObject` style brackets each property under the parent key, while `form` lifts the properties up.

| `style` | `explode` | `{ filter: { name: 'odie', age: 3 } }` |
| --- | --- | --- |
| `deepObject` | `true` | `filter[name]=odie&filter[age]=3` |
| `form` | `true` | `name=odie&age=3` |
| `form` | `false` | `filter=name,odie,age,3` |

### Reserved characters

Set `allowReserved: true` to leave the reserved set (`:/?#[]@!$&'()*+,;=`) unencoded. This suits a value that is already a path or contains a delimiter the server reads:

```typescript
client.setConfig({ querySerializer: { allowReserved: true } })
// { redirect: '/pets/1' } -> redirect=/pets/1
```

With the default `allowReserved: false` the same value encodes to `redirect=%2Fpets%2F1`.

## Pass your own function

When the knobs do not cover your case, set `querySerializer` to a function. It receives the query object and returns the search string without the leading `?`:

```typescript
import qs from 'qs'
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  querySerializer: (params) => qs.stringify(params, { arrayFormat: 'brackets' }),
})
```

Kubb passes the resolved query, including any values an `auth` resolver placed there, and appends whatever you return to the URL.

## Where to set it

The `querySerializer` rides the same `ClientConfig` as `baseURL` and `auth`, so you set it the same three ways. Both the function and the options object work in every spot.

Call `client.setConfig({ querySerializer })` to cover the whole app at once, since every generated function imports the shared `client`. Call `createClient({ querySerializer })` for an isolated client you pass on the `client` option. Pass `querySerializer` on a single request to override both for that one call.

## See also

- [Custom transport](/docs/5.x/guides/transport)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
</content>
</invoke>
