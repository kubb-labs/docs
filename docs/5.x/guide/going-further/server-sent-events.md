---
layout: doc

title: Server-sent events in the generated client - stream typed SSE
description: Consume a text/event-stream operation from the client Kubb generates. Iterate typed Server-Sent Events with for-await, read the native response, and stop the stream with an AbortSignal.
outline: deep
---

# Server-sent events

An operation that returns `text/event-stream` streams its response instead of resolving to one
body. Kubb generates a function for it that hands back a typed event stream you read with
`for await`, rather than the usual `RequestResult`. The events stay typed from the spec, and the
native response stays reachable alongside them.

Both `@kubb/plugin-fetch` and `@kubb/plugin-axios` support this. On axios, streaming needs the
fetch adapter, which Kubb selects for a stream request unless you set an adapter yourself.

## Consume a stream

A streaming operation returns an `EventStreamResult`: a `stream` to iterate and the native
`response`. Loop over the stream with `for await` and read each event's `data`:

```typescript
import { streamEvents } from './gen/clients/streamEvents'

const { stream } = await streamEvents({})

for await (const event of stream) {
  console.info(event.data)
}
```

`data` is typed from the operation's response schema. Each event also carries the optional SSE
fields, so you can branch on the event name or read the id:

```typescript
type ServerSentEvent<TData> = {
  data: TData
  event?: string
  id?: string
  retry?: number
}
```

The runtime parses each event's `data` as JSON when it is valid and keeps it as the raw string
otherwise, so a stream of JSON payloads arrives already decoded.

## Stop early

Break out of the loop to stop reading. The underlying reader is canceled when the iterator
finishes, so an early `break` releases the stream:

```typescript
const { stream } = await streamEvents({})

for await (const event of stream) {
  if (event.event === 'done') break
  render(event.data)
}
```

To stop a stream from outside the loop, pass an `AbortSignal` and abort it. Aborting ends the
request and the iteration:

```typescript
const controller = new AbortController()
const { stream } = await streamEvents({ signal: controller.signal })

// elsewhere, for example on component unmount
controller.abort()
```

## Read the response

The native `response` sits next to the stream, so status and headers are there before you start
reading events. This is the place to check a header the server sets when the stream opens:

```typescript
const { stream, response } = await streamEvents({})

console.info(response.status) // 200
console.info(response.headers.get('x-stream-id'))

for await (const event of stream) {
  handle(event.data)
}
```

## Handle errors

A stream that fails to open rejects before you reach the loop, so the `await` that starts it is
where a failed handshake surfaces. Wrap it to catch a non-2xx or a connection that never
established:

```typescript
import { ResponseError } from './gen/clients/.kubb/client'

try {
  const { stream } = await streamEvents({})
  for await (const event of stream) {
    handle(event.data)
  }
} catch (error) {
  if (error instanceof ResponseError) {
    console.error('stream rejected', error.status)
  }
}
```

A drop mid-stream ends the `for await` loop. Track the last event's `id` if you need to reconnect
from where the stream stopped.

## See also

- [Call operations](/docs/5.x/guide/going-further/calling-operations)
- [Error handling](/docs/5.x/guide/going-further/error-handling)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch)
- [`@kubb/plugin-axios`](/plugins/plugin-axios)
