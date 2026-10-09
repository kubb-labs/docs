## Errors and transport

The generated hooks call the client operation with `throwOnError: true`, so failures surface through the query library's `error` state, typed from the spec's error responses. Transport concerns (base URL, authentication, interceptors, serialization, validation) live on the client plugin: see the [plugin-fetch](/plugins/plugin-fetch/) or [plugin-axios](/plugins/plugin-axios/) guides.
