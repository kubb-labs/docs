---
layout: doc
title: Use Kubb with Context7
description: Connect Context7 to your AI assistant and use current Kubb documentation when generating code or configuring Kubb.
outline: [2, 3]
---

# Use Kubb with Context7

[Context7](https://context7.com) gives AI assistants access to current library documentation and
code examples. Kubb's documentation is indexed under the library ID `/kubb-labs/docs`.

## Set up Context7

Run the interactive setup and select your AI assistant:

```shell [Terminal]
npx ctx7 setup
```

The setup connects Context7 through MCP or installs its documentation skill, depending on the
option you select.

## Use Kubb documentation

Include `use context7` in your prompt. Add the Kubb library ID when you want to skip library
discovery:

```text [Prompt]
Create a kubb.config.ts that generates TypeScript types, a Fetch client, and React Query hooks
from ./petStore.yaml. Use Context7 library /kubb-labs/docs.
```

You can also add a rule to your assistant's instructions so it uses Context7 automatically for
Kubb configuration and API questions.

## See also

- [Kubb on Context7](https://context7.com/kubb-labs/docs)
- [Context7 setup](https://context7.com/docs/clients/cli)
- [Kubb MCP server](/docs/5.x/ai/mcp)
