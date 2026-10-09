
# Server-sent events

Operations returning `text/event-stream` produce a typed stream rather than a `RequestResult`. Both clients support streaming. Axios uses its fetch adapter unless you select another adapter.

## Consume a stream

Read the `EventStreamResult.stream` with `for await`:

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
otherwise.

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

Read status and headers from the native `response` before iterating:

```typescript
const { stream, response } = await streamEvents({})

console.info(response.status) // 200
console.info(response.headers.get('x-stream-id'))

for await (const event of stream) {
  handle(event.data)
}
```

## Handle errors

Catch connection failures and non-2xx responses around the call and iteration:

```typescript
import { ResponseError } from './gen/.kubb/client'

try {
  const { stream } = await streamEvents({})
  for await (const event of stream) {
    handle(event.data)
  }
} catch (error) {
  if (ResponseError.is(error)) {
    console.error('stream rejected', error.status)
  }
}
```

> [!NOTE]
> A drop mid-stream ends the `for await` loop. Track the last event's `id` if you need to reconnect
> from where the stream stopped.

## See also

- [Call operations](/plugins/plugin-fetch/guide/calling-operations)
- [Error handling](/plugins/plugin-fetch/guide/error-handling)
- [`@kubb/plugin-fetch`](/plugins/plugin-fetch/)
- [`@kubb/plugin-axios`](/plugins/plugin-axios/)
