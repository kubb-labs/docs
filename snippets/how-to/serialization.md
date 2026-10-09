# Configure serialization

The generated client encodes parameters using OpenAPI `style` and `explode`, serializes request bodies by content type, and decodes responses by media type. Generated operations carry the metadata. Most requests need no additional configuration.

## Override parameter serialization

Check the [default parameter styles and encoding](/docs/5.x/reference/serialization#parameter-styles) before replacing a serializer.

Override `serializer.query`, `.body`, or `.path` on the client. Omitted functions retain their defaults:

```typescript
import { client } from './gen/.kubb/client'
import qs from 'qs'

client.setConfig({
  serializer: {
    query: (params) => qs.stringify(params, { arrayFormat: 'brackets' }),
  },
})
```

A serializer set this way runs for every call, but you can pass `serializer` on a single call to
override only that request.

## Encode request bodies

The request content type decides how the body is encoded. The default serializer handles the
common types: a plain object becomes JSON, `multipart/form-data` becomes `FormData`, and
`application/x-www-form-urlencoded` becomes `URLSearchParams`. Binary and already-encoded bodies
(`FormData`, `URLSearchParams`, `Blob`, `ArrayBuffer`, typed arrays, and strings) pass through
untouched.

When an operation declares a single request content type, Kubb sets it on the generated function,
so you pass only the body. For an operation that accepts more than one, set `contentType` on the
call.

> [!NOTE]
> When the body is `FormData`, the runtime removes any `Content-Type` header so the transport sets
> it with the multipart boundary. You do not need to set `multipart/form-data` yourself, and a
> value you set is dropped for that request.

To encode a content type the default serializer does not handle, register a codec for that media
type. `codecs` is keyed by content type, and each entry holds a `serialize` for the request body
and a `deserialize` for the response, so either half is optional:

```typescript
import { client } from './gen/.kubb/client'
import { stringify } from 'yaml'

client.setConfig({
  codecs: {
    'application/yaml': { serialize: (body) => stringify(body) },
  },
})
```

## Decode responses

The runtime reads the response `Content-Type` and decodes the body by it: JSON is parsed, text
stays a string, and a binary type becomes a `Blob`. The negotiated media type is on the result as
`contentType`, so a `switch (result.contentType)` narrows `data` for an operation that returns
more than one.

To decode a media type the runtime does not handle, register a codec's `deserialize` for it. It
receives the raw body and the content type and returns the parsed value, and runs before
validation, so a custom format is transformed first and then checked against its schema:

```typescript
import { client } from './gen/.kubb/client'

client.setConfig({
  codecs: {
    'application/xml': { deserialize: (raw) => new DOMParser().parseFromString(raw as string, 'application/xml') },
  },
})
```

Like the other config, `codecs` can also be passed on a single call, and a per-call entry merges
over the client one for that content type.

When the runtime picks the wrong parse mode because a response omits its `Content-Type` or sets a
misleading one, force the mode with `responseType` on the call. It accepts `'json'`, `'text'`,
`'blob'`, `'arraybuffer'`, and `'document'` (`@kubb/plugin-axios` adds `'formdata'`):

```typescript
const { data } = await downloadInvoice({ path: { id: '123' }, responseType: 'blob' })
// data is a Blob even when the server leaves Content-Type unset
```

The server-sent events guide covers `responseType: 'stream'`.

For bidirectional formats, supply both `serialize` and `deserialize` in the media type codec, then set the operation's request and response `contentType`.

## Validate responses

Enable `validator` on the client plugin and register `pluginZod` in the same configuration. Validation is disabled by default. `pluginAxios` takes the same option.

```typescript twoslash
import { pluginFetch } from '@kubb/plugin-fetch'

pluginFetch({ validator: 'zod' })
```

`'zod'` validates the success response body, and the error body when a non-2xx call does not
throw. Use the object form to opt in per direction, where `request` validates the request
body before the call goes out:

```typescript
pluginFetch({ validator: { request: 'zod', response: 'zod' } })
```

With a validator set, Kubb passes the matching schema to each generated call, and the runtime
parses the body through it. The schemas are Standard Schema compatible, so this works the same
with Zod, valibot, and arktype. A body that does not match throws a `ParseError` carrying the
schema's `issues`, covered in the error handling guide.
