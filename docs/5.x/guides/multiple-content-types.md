---
layout: doc

title: Multiple content types in Kubb - negotiate and discriminate request and response formats
description: Pick the request body format and the response format a generated call uses, parse non-JSON bodies with your own deserializers, and narrow the result by the content type the server returned.
outline: deep
---

# Multiple content types

An OpenAPI operation can declare more than one content type for its request body, its responses, or both. A `PUT /pet` might accept `application/json` and `application/xml` for the body and return either format for `200`. The generated client lets a call choose which format to send, which format to prefer back, and then reports the format the server actually returned so you can read the body with full types.

## Choosing the request and response format

Every generated call accepts a `contentType` option. Pass an object with a `request` key, a `response` key, or both.

```typescript
const result = await updatePet({
  body: { name: 'Fluffy', id: 1, photoUrls: [] },
  contentType: { request: 'application/json', response: 'application/xml' },
})
```

The `request` key sets the `Content-Type` header and picks the body serializer. The `response` key sets the `Accept` header so the server knows which format you prefer. Both keys are optional, and a bare string still selects the request type, so `contentType: 'application/json'` keeps working.

Kubb only offers the keys an operation can actually vary. A request body with a single content type bakes that type into the call, so the option exposes `response` alone. A response with a single content type needs no choice at all. When the spec declares several request types, the first one is the default, and you override it per call.

## Reading the response by content type

When a status documents more than one content type, the result carries the format the server returned on `result.parsed`. The `parsed` field pairs the negotiated `contentType` with `data` typed for that format, so a `switch` narrows the body.

```typescript
const result = await getPetById({ path: { petId: '1' }, contentType: { response: 'application/xml' } })

if (result.status === 200) {
  const { data, contentType } = result.parsed

  switch (contentType) {
    case 'application/json':
      console.log('JSON pet:', data.name)
      break
    case 'application/xml':
      console.log('XML pet:', data.id)
      break
  }
}
```

`result.data` still holds the plain body for callers that do not care which format arrived. The `parsed` field is the typed, discriminated view on top of it. A thrown `ResponseError` carries the same negotiated `contentType`.

## Parsing non-JSON bodies

The runtime decodes JSON and text on its own. For a format like XML or CSV, register a deserializer so the body becomes an object before validation runs. A deserializer is a function keyed by content type, set on the client or on a single call.

```typescript
import { XMLParser } from 'fast-xml-parser'

const xml = new XMLParser()

const result = await getPetById({
  path: { petId: '1' },
  contentType: { response: 'application/xml' },
  deserializers: { 'application/xml': (raw) => xml.parse(raw as string) },
})
```

Kubb matches the key against the response `Content-Type` with any charset stripped, so `application/xml; charset=utf-8` still finds the `application/xml` entry. Without a matching deserializer, a non-JSON body stays the raw string.

The request side mirrors this with `bodySerializers`, a map keyed by content type that turns the body into the wire format. The built-in JSON, `multipart/form-data`, and `application/x-www-form-urlencoded` handling stays in place for every type you do not override.

```typescript
const result = await updatePet({
  body: { name: 'Fluffy', id: 1, photoUrls: [] },
  contentType: { request: 'application/xml' },
  bodySerializers: { 'application/xml': (body) => toXml(body) },
})
```

## Single content types

Operations that declare one content type generate the same output as before. The `contentType` option only gains the keys an operation can vary, and the discriminated `parsed` view only appears where a status documents several formats, so existing code keeps compiling without changes.
