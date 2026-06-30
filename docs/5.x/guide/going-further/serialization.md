---
layout: doc

title: Serialization and parsing in the generated client - parameters, bodies, and responses
description: Control how Kubb encodes path, query, header, and cookie parameters, serializes request bodies per content type, and decodes and validates responses in the generated Fetch and Axios client.
outline: deep
---

# Serialization and parsing

Between the typed parameters you pass and the typed result you read, the client does the encoding
and decoding. It reads each parameter's OpenAPI `style` and `explode` from your spec, picks a body
encoder from the request content type, and decodes the response by its media type. Most of this
needs no configuration: Kubb bakes the per-parameter metadata into each generated function. This
page covers what it does by default and how to override each step.

The behavior is identical for [`@kubb/plugin-fetch`](/plugins/plugin-fetch) and [`@kubb/plugin-axios`](/plugins/plugin-axios).

## Parameter styles

OpenAPI describes how each parameter is rendered with a `style` and an `explode` flag, and the
two differ by location. Kubb generates the metadata from your spec and the runtime applies it, so
a parameter declared as `pipeDelimited` in the spec serializes that way without any code on your
side. The generated call carries it:

```typescript
// generated from the spec, you do not write this
request({
  method: 'GET',
  url: '/pets/{petId}',
  serialization: {
    path: { petId: { style: 'matrix', explode: true } },
    query: { tags: { style: 'pipeDelimited', explode: false } },
  },
  ...config,
})
```

### Query

Query parameters default to the `form` style. Arrays explode into repeated keys unless the spec
says otherwise, and `spaceDelimited`, `pipeDelimited`, and `deepObject` change how arrays and
objects collapse.

| Style              | `explode` | Input              | Result            |
| ------------------ | --------- | ------------------ | ----------------- |
| `form` (default)   | `true`    | `{ id: [3, 4, 5] }` | `id=3&id=4&id=5`  |
| `form`             | `false`   | `{ id: [3, 4, 5] }` | `id=3,4,5`        |
| `spaceDelimited`   | `false`   | `{ id: [3, 4, 5] }` | `id=3%204%205`    |
| `pipeDelimited`    | `false`   | `{ id: [3, 4, 5] }` | `id=3\|4\|5`      |
| `deepObject`       | `n/a`     | `{ a: { b: 1 } }`  | `a%5Bb%5D=1`      |

With `explode: true`, `spaceDelimited` and `pipeDelimited` fall back to repeated keys like `form`,
so the delimiter only shows with `explode: false`.

### Path

Path parameters default to the `simple` style, which emits the bare value. `label` prefixes a
`.` and `matrix` prefixes a `;name=` segment. The results below are the serialized segment for a
parameter named `id`.

| Style              | `explode` | Input            | Result             |
| ------------------ | --------- | ---------------- | ------------------ |
| `simple` (default) | `false`   | `[3, 4, 5]`      | `3,4,5`            |
| `label`            | `true`    | `[3, 4, 5]`      | `.3.4.5`           |
| `matrix`           | `true`    | `[3, 4, 5]`      | `;id=3;id=4;id=5`  |
| `simple`           | `false`   | `{ x: 1, y: 2 }` | `x,1,y,2`          |

### Header and cookie

Header parameters use the `simple` style and cookie parameters use the `form` style. Both fix the
style and only let `explode` vary, so the metadata for these locations carries `explode` alone.
Header values are sent as-is, and cookie values are URL-encoded into a single `Cookie` header.

| Location | `explode` | Input                            | Result                  |
| -------- | --------- | -------------------------------- | ----------------------- |
| header   | `false`   | `[3, 4]`                         | `X-Ids: 3,4`            |
| header   | `true`    | `{ role: 'admin' }`              | `X-Filter: role=admin`  |
| cookie   | `false`   | `{ session: 'abc', ids: [1, 2] }` | `session=abc; ids=1,2`  |
| cookie   | `true`    | `{ ids: [1, 2] }`                | `ids=1; ids=2`          |

### Override the serializer

To change how a location is encoded across the board, pass your own serializer on the client.
`serializer` groups a `query`, `body`, and `path` function, each falling back to the built-in
default when omitted:

```typescript
import { client } from './gen/clients/.kubb/client'
import qs from 'qs'

client.setConfig({
  serializer: {
    query: (params) => qs.stringify(params, { arrayFormat: 'brackets' }),
  },
})
```

A serializer set this way runs for every call. Pass `serializer` on a single call to override just
that request.

## Request bodies

The request content type decides how the body is encoded. The default serializer handles the
common types: a plain object becomes JSON, `multipart/form-data` becomes `FormData`, and
`application/x-www-form-urlencoded` becomes `URLSearchParams`. Binary and already-encoded bodies
(`FormData`, `URLSearchParams`, `Blob`, `ArrayBuffer`, typed arrays, and strings) pass through
untouched.

```typescript
// body { name: 'odie' }                                    -> {"name":"odie"}
// body { field: 'x' }, multipart/form-data                 -> FormData
// body { plan: 'pro' }, application/x-www-form-urlencoded  -> URLSearchParams
```

When an operation declares a single request content type, Kubb sets it on the generated function,
so you pass only the body. For an operation that accepts more than one, set
[`contentType`](/docs/5.x/guide/going-further/calling-operations#set-the-content-type) on the
call.

> [!NOTE]
> A `FormData` body keeps its `Content-Type` unset on purpose, so the runtime can append the
> multipart boundary. Setting `Content-Type: multipart/form-data` by hand drops the boundary and
> the request breaks.

To encode a content type the default serializer does not handle, register a body serializer for
that media type. `bodySerializers` is keyed by content type:

```typescript
import { client } from './gen/clients/.kubb/client'
import { stringify } from 'yaml'

client.setConfig({
  bodySerializers: {
    'application/yaml': (body) => stringify(body),
  },
})
```

## Response decoding

The runtime reads the response `Content-Type` and decodes the body by it: JSON is parsed, text
stays a string, and a binary type becomes a `Blob`. The negotiated media type is on the result as
`contentType`, so a `switch (result.contentType)` narrows `data` for an operation that returns
more than one.

To decode a media type the runtime does not handle, register a deserializer for it. A deserializer
receives the raw body and the content type and returns the parsed value. It runs before
validation, so a custom format is transformed first and then checked against its schema:

```typescript
import { client } from './gen/clients/.kubb/client'

client.setConfig({
  deserializers: {
    'application/xml': (raw) => new DOMParser().parseFromString(raw as string, 'application/xml'),
  },
})
```

Like the other config, `deserializers` can also be passed on a single call, and a per-call entry
merges over the client one for that request.

When the runtime picks the wrong parse mode because a response omits its `Content-Type` or sets a
misleading one, force the mode with `responseType` on the call. It accepts `'json'`, `'text'`,
`'blob'`, `'arraybuffer'`, and `'document'` (`@kubb/plugin-axios` adds `'formdata'`):

```typescript
const { data } = await downloadInvoice({ path: { id: '123' }, responseType: 'blob' })
// data is a Blob even when the server leaves Content-Type unset
```

For `responseType: 'stream'`, see [server-sent events](/docs/5.x/guide/going-further/server-sent-events).

## Send and receive XML

To talk XML in both directions, register a `bodySerializer` and a `deserializer` for the same
media type. The body serializer turns the request object into XML, the deserializer turns the XML
response back into data, and `contentType` sets the request `Content-Type` and the `Accept` header
so the server answers in XML. The example below uses `fast-xml-parser` for plain-object data,
where the `DOMParser` deserializer above returns a DOM `Document` instead:

```typescript
import { client } from './gen/clients/.kubb/client'
import { XMLBuilder, XMLParser } from 'fast-xml-parser'

const builder = new XMLBuilder()
const parser = new XMLParser()

client.setConfig({
  bodySerializers: { 'application/xml': (body) => builder.build(body) },
  deserializers: { 'application/xml': (raw) => parser.parse(raw as string) },
})
```

With both registered, set `contentType` on a call to send and accept XML for that request:

```typescript
const { data } = await updatePet({
  path: { petId: '123' },
  body: { pet: { name: 'Fluffy', status: 'sold' } },
  contentType: { request: 'application/xml', response: 'application/xml' },
})
// the body is built to XML, and data is parsed from the XML response
```

When the spec already types an operation as XML, Kubb sets the content type for you and you pass
only the body. Set `contentType` yourself for an operation that offers more than one media type.

## Response validation

Validation is off by default. Turn it on with the [`validator`](/plugins/plugin-fetch) plugin
option to check request and response bodies against schemas from `@kubb/plugin-zod`:

```typescript
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ validator: 'zod' })
```

`'zod'` validates the success response body, and the error body when a non-2xx call does not
throw. Use the object form to opt in per direction, where `request` also validates the request
body and query before the call goes out:

```typescript
pluginFetch({ validator: { request: 'zod', response: 'zod' } })
```

With a validator set, Kubb passes the matching schema to each generated call, and the runtime
parses the body through it. The schemas are Standard Schema compatible, so this works the same
with Zod, valibot, and arktype. A body that does not match throws a `ParseError` carrying the
schema's `issues`, covered in
[error handling](/docs/5.x/guide/going-further/error-handling#validation-failures).

> [!TIP]
> Validation guarantees the data matches its type at runtime, at the cost of parsing every body.
> Leave it off when you trust the API and need the throughput, and turn it on where a malformed
> response is hard to trace.

## See also

- [Call operations](/docs/5.x/guide/going-further/calling-operations)
- [Error handling](/docs/5.x/guide/going-further/error-handling)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
- [`@kubb/plugin-zod`](/plugins/plugin-zod)
