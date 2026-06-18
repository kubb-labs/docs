---
layout: doc

title: Use Kubb with Claude AI - AI Integration Guide
description: Integrate Kubb with Claude AI for enhanced code generation. AI-powered OpenAPI analysis and code suggestions.
outline: deep
---

# Set up Claude with Kubb

![Claude](/public/screenshots/claude.png)

[Kubb](https://kubb.dev) and [Claude](https://claude.ai) connect over [MCP](https://modelcontextprotocol.io), the Model Context Protocol. Claude calls your API through plain conversation.

Kubb generates type-safe code from your OpenAPI spec. That includes the API client files, the Zod schemas, and an MCP server. Claude reads the MCP server and runs the matching API calls as you chat. You describe what you want, Claude makes the call.

```mermaid
graph TD
  A[Kubb<br/>Generates code from OpenAPI] --> B[MCP Server<br/>Handles tool calls]
  B --> C[Claude<br/>Conversational AI]
  C -->|Sends tool request| B
  B -->|Uses generated code| A
```

```mermaid
flowchart LR
  subgraph "Your Computer"
    Host["MCP Host (e.g., Claude Desktop, IDEs)"]
    S1["MCP Server A"]
    S2["MCP Server B"]
    S3["MCP Server C"]
    D1["Local Data Source A"]
    D2["Local Data Source B"]
    Host -->|MCP Protocol| S1
    Host -->|MCP Protocol| S2
    Host -->|MCP Protocol| S3
    S1 <--> D1
    S2 <--> D2
  end

  subgraph "Internet"
    D3["Remote Service C"]
    S3 <--> D3
  end

```

## Installation

First, install [Claude desktop](https://claude.ai/download) and work through the [user quickstart](https://modelcontextprotocol.io/quickstart/user).

Then install Kubb with the [MCP plugin](/plugins/plugin-mcp).

> [!IMPORTANT]
> Requires Kubb `v3.10.0` or higher.

> [!TIP]
> The MCP plugin works with the [OAS adapter](/adapters/adapter-oas), [TypeScript](/plugins/plugin-ts), and [Zod](/plugins/plugin-zod) plugins to generate every file it needs.

::: code-group

```shell [bun]
bun add -d @kubb/plugin-mcp@beta @kubb/adapter-oas@beta @kubb/plugin-ts@beta @kubb/plugin-zod@beta
```

```shell [pnpm]
pnpm add -D @kubb/plugin-mcp@beta @kubb/adapter-oas@beta @kubb/plugin-ts@beta @kubb/plugin-zod@beta
```

```shell [npm]
npm install --save-dev @kubb/plugin-mcp@beta @kubb/adapter-oas@beta @kubb/plugin-ts@beta @kubb/plugin-zod@beta
```

```shell [yarn]
yarn add -D @kubb/plugin-mcp@beta @kubb/adapter-oas@beta @kubb/plugin-ts@beta @kubb/plugin-zod@beta
```

:::

## Define `kubb.config.ts`

Write a `kubb.config.ts` that sets up the [MCP](https://modelcontextprotocol.io) server.

> [!IMPORTANT]
> Set a `baseURL` so the generated client knows which host to call.

```typescript [kubb.config.ts] twoslash
import { defineConfig } from 'kubb'
import { adapterOas } from '@kubb/adapter-oas'
import { pluginTs } from '@kubb/plugin-ts'
import { pluginMcp } from '@kubb/plugin-mcp'
import { pluginZod } from '@kubb/plugin-zod'

export default defineConfig({
  input: {
    path: './petStore.yaml',
  },
  output: {
    path: './src/gen',
  },
  adapter: adapterOas(),
  plugins: [
    pluginTs(),
    pluginMcp({
      client: {
        baseURL: 'https://petstore.swagger.io/v2', // [!code ++]
      },
    }),
  ],
})
```

## Generate MCP files

```shell
npx kubb@beta generate
```

## Inspect the generated files

The `src/mcp` folder holds the files that build an [MCP server](https://modelcontextprotocol.io) and connect [Claude](https://claude.ai/download) to your API.

```
.
├── src/
│   └── mcp/
│   │   ├── addPet.ts
│   │   └── getPet.ts
│   │   └── mcp.json
│   │   └── server.ts
│   └── zod/
│   │   ├── addPetSchema.ts
│   │   └── getPetSchema.ts
│   └── models/
│   │   ├── AddPet.ts
│   │   └── GetPet.ts
│   └── index.ts
├── petStore.yaml
├── kubb.config.ts
└── package.json
```

### src/mcp/addPet.ts

The `addPetHandler` function takes pet data and sends a POST request to the Swagger PetStore API. It returns the response as a JSON text message that [MCP](https://modelcontextprotocol.io) uses in conversations.

```typescript [src/mcp/addPet.ts]
import client from '@kubb/plugin-clients/client/axios'
import type { AddPetMutationRequest, AddPetMutationResponse, AddPet405 } from '../models/AddPet'
import type { CallToolResult } from '@modelcontextprotocol/sdk/types'

export async function addPetHandler({ data }: { data: AddPetMutationRequest }): Promise<Promise<CallToolResult>> {
  const res = await client<AddPetMutationResponse, ResponseErrorConfig<AddPet405>, AddPetMutationRequest>({
    method: 'POST',
    url: '/pet',
    baseURL: 'https://petstore.swagger.io/v2',
    data,
  })
  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify(res.data),
      },
    ],
  }
}
```

### src/mcp/mcp.json

This config registers an [MCP](https://modelcontextprotocol.io) server named `"Swagger PetStore - OpenAPI 3.0"`. The name comes from `info.title` in your OpenAPI file.

It runs the TypeScript server (`server.ts`) through `tsx`, so [MCP](https://modelcontextprotocol.io) handles tool calls over standard input and output.

```JSON [src/mcp/mcp.json]
{
  "mcpServers": {
    "Swagger PetStore - OpenAPI 3.0": {
      "type": "stdio",
      "command": "npx",
      "args": ["tsx", "/mcp/src/gen/mcp/server.ts"]
    }
  }
}


```

### src/mcp/server.ts

This code starts an [MCP](https://modelcontextprotocol.io) server for the Swagger PetStore API in four steps:

1. Import the MCP SDK classes and the `addPetHandler` function.
2. Create an MCP server named `"Swagger PetStore - OpenAPI 3.0"`.
3. Register the `addPet` tool. It calls `addPetHandler` with pet data validated against `addPetMutationRequestSchema`, generated by the Zod plugin.
4. Connect the server to a `stdio` transport so it talks over standard input and output.

```typescript [src/mcp/server.ts]
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio'

import { addPetHandler } from './addPet'
import { addPetMutationRequestSchema } from '../zod/addPetSchema'

export const server = new McpServer({
  name: 'Swagger PetStore - OpenAPI 3.0',
  version: '3.0.3',
})

server.tool('addPet', 'Add a new pet to the store', { data: addPetMutationRequestSchema }, async ({ data }) => {
  return addPetHandler({ data })
})

async function startServer() {
  try {
    const transport = new StdioServerTransport()
    await server.connect(transport)
  } catch (error) {
    console.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()
```

## Start Claude with the MCP server

Point [Claude](https://claude.ai) at your [MCP](https://modelcontextprotocol.io) server config (`src/mcp/mcp.json`). Open Claude desktop and go to settings.

![Claude setup 1](/public/screenshots/claude-setup1.png)

In the settings panel, open the `developer` section and click `edit config`. A window shows where the JSON file that lists your [MCP](https://modelcontextprotocol.io) servers lives.

> [!TIP]
> Manually navigate to:
>
> - Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`
> - Windows: `%APPDATA%\Claude\claude_desktop_config.json`

![Claude setup 2](/public/screenshots/claude-setup2.png)

Copy the content of `src/mcp/mcp.json` so [Claude](https://claude.ai) picks up your [MCP](https://modelcontextprotocol.io) server.

> [!TIP]
> With multiple MCP servers, append your entry instead of overwriting the file.

For example:

```JSON [~/Library/Application Support/Claude/claude_desktop_config.json]
{
  "mcpServers": {
    "Swagger PetStore - OpenAPI 3.0": {
      "type": "stdio",
      "command": "npx",
      "args": ["tsx", "mcp/src/gen/mcp/server.ts"]
    },
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "mcp/github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<YOUR_TOKEN>"
      }
    }
  }
}
```

## Validate your MCP server

Quit [Claude](https://claude.ai) and reopen the desktop app. Click the button below to check that your [MCP](https://modelcontextprotocol.io) server is connected.

![Claude](/public/screenshots/claude-setup3.png)

The view below opens and shows your generated [MCP](https://modelcontextprotocol.io) server.

![Claude](/public/screenshots/claude-setup4.png)

## Use your MCP server

The prompt `create a random pet` reaches your [MCP](https://modelcontextprotocol.io) server. The server maps it to the `addPet` tool, which calls `addPetHandler` and creates the pet.

![Claude interaction](/public/screenshots/claude-interaction.gif)

## See also

- [MCP setup](https://modelcontextprotocol.io)
- [Claude](https://claude.ai)
