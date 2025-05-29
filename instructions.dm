# WhatsApp MCP Server — Project Instructions

## What This Project Does

This project implements a Model Context Protocol (MCP) server for WhatsApp, enabling AI agents (such as Claude) to:
- Search and read personal WhatsApp messages (including text, images, videos, documents, and audio).
- Search contacts and send messages to individuals or groups.
- Send and receive media files (images, videos, documents, audio messages).
- Integrate with Claude Desktop or Cursor for AI-powered WhatsApp interactions.

## Technologies Used & Key Features

- **Go (whatsapp-bridge/)**: 
  - Connects to WhatsApp Web via [whatsmeow](https://github.com/tulir/whatsmeow).
  - Handles authentication (QR code, multi-device support).
  - Stores all messages, chats, and media metadata in a local SQLite database (`store/messages.db`).
  - Exposes a REST API for the Python server to interact with WhatsApp data and trigger actions (send message, download media, etc.).
  - Implements robust message and chat indexing for efficient search and retrieval.
  - Media download and storage support, including metadata and file management.
  - Windows support via CGO for go-sqlite3 (requires C compiler).

- **Python 3.6+ (whatsapp-mcp-server/)**:
  - Implements the MCP protocol using the `FastMCP` server.
  - Exposes tools as Python functions with `@mcp.tool()` decorators for easy extensibility.
  - Interacts with the Go bridge via REST and directly with the SQLite database for queries.
  - Provides tools for searching contacts, listing messages/chats, sending messages/files/audio, and downloading media.
  - Modular design: core WhatsApp logic in `whatsapp.py`, audio conversion in `audio.py`, entry point in `main.py`.
  - Uses [UV](https://astral.sh/uv/) for Python environment management.

- **SQLite**:
  - Central data store for all WhatsApp messages, chats, and media metadata.
  - Schema supports efficient search, filtering, and context retrieval.

- **FFmpeg** (optional):
  - Used for converting audio files to WhatsApp-compatible `.ogg` Opus format for voice messages.
  - Automatically invoked by the Python server if available; otherwise, raw audio is sent as files.

- **Integration**:
  - Claude Desktop and Cursor integration via configuration JSON files.
  - All data is stored locally; messages are only sent to LLMs when explicitly accessed.

## Architecture Overview

- **Go WhatsApp Bridge** (`whatsapp-bridge/`): Handles WhatsApp API, authentication, message/media storage, and exposes a REST API.
- **Python MCP Server** (`whatsapp-mcp-server/`): Exposes standardized tools for AI agents to interact with WhatsApp data, calling the Go bridge and SQLite as needed.
- **Data Flow**: Claude ⇄ Python MCP Server ⇄ Go Bridge (REST/SQLite) ⇄ WhatsApp Web API ⇄ SQLite DB

## Key Features & Tools (Implemented)

- **Contact and Chat Search**: Search contacts, list chats, retrieve chat info.
- **Message Retrieval**: List messages, get message context, retrieve last interactions, filter by sender, chat, or content.
- **Messaging**: Send text, files, and audio messages (with format conversion if FFmpeg is available).
- **Media Handling**: Download and send images, videos, documents, and audio; retrieve media metadata and file paths.
- **Extensible Tooling**: Tools are exposed via the MCP protocol, making it easy to add new capabilities for Claude or other LLMs.
- **Windows Compatibility**: CGO and C compiler support for go-sqlite3.

## Extending the Project

- **Add New Tools**: Implement new Python functions in the MCP server to expose additional WhatsApp or database features.
- **Integrate More AI Agents**: Adapt the MCP server to support other LLMs or agent frameworks.
- **Enhance Media Support**: Add support for more media types or advanced media processing.
- **Improve Search/Indexing**: Optimize or extend the SQLite schema for faster or more flexible queries.
- **Security/Privacy**: Add encryption, access controls, or audit logging for sensitive data.
- **Improve Error Handling**: Add more robust error handling and logging in both Go and Python components.
- **Automated Testing**: Add unit and integration tests for both Go and Python codebases.
- **Documentation**: Expand developer and user documentation, including API references and usage examples.
- **Configuration Management**: Add support for environment-based configuration and secrets management.
- **Performance Monitoring**: Add metrics and health checks for both the Go bridge and Python server.

## Suggested Improvements & Tasks

1. **Security Enhancements**
   - Encrypt sensitive data in SQLite and on disk.
   - Add authentication and authorization to the REST API.
   - Implement audit logging for message access and actions.

2. **Reliability & Monitoring**
   - Add health checks and status endpoints to both Go and Python servers.
   - Integrate logging and monitoring (e.g., Prometheus, Grafana).

3. **Testing & CI**
   - Add automated tests (unit, integration, end-to-end) for all major features.
   - Set up CI/CD pipelines for linting, testing, and deployment.

4. **Extensibility**
   - Modularize the Python tool interface for easier plugin development.
   - Add support for more LLMs or agent frameworks.
   - Expose more WhatsApp features (e.g., group management, message reactions).

5. **User Experience**
   - Improve error messages and troubleshooting guidance.
   - Add CLI or web UI for easier management and debugging.

6. **Documentation**
   - Expand README and instructions with API usage examples, architecture diagrams, and developer onboarding guides.
   - Maintain a changelog and roadmap for future development.

## Setup & Integration Notes

- Requires both Go and Python environments.
- Authentication with WhatsApp is via QR code (multi-device support).
- Claude Desktop or Cursor integration is via configuration JSON files.
- All data is stored locally; messages are only sent to LLMs when explicitly accessed.
- For Windows, ensure CGO is enabled for go-sqlite3 and a C compiler is installed.
- Use FFmpeg for best audio compatibility.
- See README.md for detailed troubleshooting steps.

## Architecture Diagram

See `architecture.png` for a visual overview of the system:

```
Claude/LLM
   │
   ▼
Python MCP Server (whatsapp-mcp-server/)
   │         │
   │         └───► SQLite (messages, chats, media)
   │
   ▼
Go WhatsApp Bridge (whatsapp-bridge/)
   │
   ▼
WhatsApp Web API
```

## API Usage Examples

### Send a WhatsApp Message

```python
from mcp.client import MCPClient

client = MCPClient("http://localhost:YOUR_MCP_PORT")
result = client.send_message(recipient="123456789@s.whatsapp.net", message="Hello from MCP!")
print(result)
```

### List Messages from a Chat

```python
messages = client.list_messages(chat_jid="123456789@g.us", limit=10)
for msg in messages:
    print(msg)
```

## Developer Onboarding

See the onboarding section in the README for step-by-step setup instructions.

## Changelog & Roadmap

- Maintain a `CHANGELOG.md` for release history and a `roadmap.md` for planned features and improvements.

---

This file is intended to help developers quickly understand the project and identify areas for extension or integration. For architectural or strategic decisions, consider maintaining a `.context/decisions/` directory as the project grows. 