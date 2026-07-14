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
