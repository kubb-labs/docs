---
layout: doc
title: Stream server-sent events
description: Consume a text/event-stream operation from the client @kubb/plugin-fetch generates, reading typed events with for-await.
outline: deep
---

# Stream server-sent events

A `text/event-stream` operation hands back a typed stream you read with `for await` instead of a single `RequestResult`, covered in full by the [server-sent events guide](/plugins/plugin-fetch/guide/server-sent-events).

```typescript
import { streamEvents } from './src/gen/clients/streamEvents'

const { stream } = await streamEvents({})

for await (const event of stream) {
  console.info(event.data)
}
```

## Output example

Generated from a `text/event-stream` operation (not part of `petStore.yaml`, added here to
demonstrate the shape), since the concept only shows up when the spec has a streaming response.

```typescript [src/gen/clients/streamEvents.ts]
import type { Options, EventStreamResult, SuccessOf } from '../.kubb/client'
import type { StreamEventsOptions, StreamEventsResponses } from '../types/StreamEvents'
import { client, toEventStream } from '../.kubb/client'

export function streamEvents<ThrowOnError extends boolean = true>(options: Options<StreamEventsOptions, ThrowOnError> = {}): Promise<EventStreamResult<SuccessOf<StreamEventsResponses>>> {
  const { client: request = client, ...config } = options

  return toEventStream<SuccessOf<StreamEventsResponses>>(request({ method: 'GET', url: '/stream/events', responseType: 'stream', ...config }))
}
```

```typescript [usage.ts]
import { streamEvents } from './src/gen/clients/streamEvents'

const { stream } = await streamEvents({})

for await (const event of stream) {
  console.info(event.data) // typed from the operation's response schema
}
```
