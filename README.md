# WhatsApp MCP Server

This is a Model Context Protocol (MCP) server for WhatsApp.

With this you can search and read your personal Whatsapp messages (including images, videos, documents, and audio messages), search your contacts and send messages to either individuals or groups. You can also send media files including images, videos, documents, and audio messages.

It connects to your **personal WhatsApp account** directly via the Whatsapp web multidevice API (using the [whatsmeow](https://github.com/tulir/whatsmeow) library). All your messages are stored locally in a SQLite database and only sent to an LLM (such as Claude) when the agent accesses them through tools (which you control).

Here's an example of what you can do when it's connected to Claude.

![WhatsApp MCP](./example-use.png)

> To get updates on this and other projects I work on [enter your email here](https://docs.google.com/forms/d/1rTF9wMBTN0vPfzWuQa2BjfGKdKIpTbyeKxhPMcEzgyI/preview)

## Installation

You can set up this project using either the Docker container method (recommended) or by installing the components directly on your system.

### Option 1: Docker Container (Recommended)

Using Docker provides a secure, isolated environment with all dependencies pre-installed, and makes the setup process much simpler.

#### Prerequisites
- Docker installed on your system

#### Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/lharries/whatsapp-mcp.git
   cd whatsapp-mcp
   ```

2. **Build the Docker image**
   ```bash
   docker build -t whatsapp-mcp:latest .
   ```

3. **Create a directory for persistent data**
   ```bash
   mkdir -p ~/whatsapp_mcp_data
   ```

4. **Run the container**
   ```bash
   docker run -it --rm \
     --name whatsapp-mcp-container \
     -v ~/whatsapp_mcp_data:/data \
     --user 1001:1001 \
     --cap-drop=ALL \
     whatsapp-mcp:latest
   ```

   The first time you run it, you will be prompted to scan a QR code. Scan the QR code with your WhatsApp mobile app to authenticate.

5. **Configure Claude Desktop or Cursor**

   For **Claude Desktop**, create or edit `claude_desktop_config.json` in your configuration directory:
   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%\Claude\claude_desktop_config.json`
   - Linux: `~/.config/Claude/claude_desktop_config.json`

   ```json
   {
     "mcpServers": {
       "whatsapp": {
         "command": "docker",
         "args": [
           "run", "-i", "--rm",
           "--name", "whatsapp-mcp-container-claude",
           "-v", "/absolute/path/to/your/whatsapp_mcp_data:/data",
           "--user", "1001:1001",
           "--cap-drop=ALL",
           "whatsapp-mcp:latest"
         ]
       }
     }
   }
   ```

   For **Cursor**, save a similar configuration as `~/.cursor/mcp.json`

   ⚠️ Important: Replace `/absolute/path/to/your/whatsapp_mcp_data` with the actual absolute path to your data directory (e.g., `/home/username/whatsapp_mcp_data` on Linux or `/Users/username/whatsapp_mcp_data` on macOS).

6. **Restart Claude Desktop / Cursor**

   After restarting, you should now see WhatsApp as an available integration.

#### Security Features

The Docker setup includes several security enhancements:
- Runs as a non-root user (UID 1001)
- Drops all Linux capabilities for enhanced security
- Isolates the application from the host system
- Uses a multi-stage build to minimize image size
- Uses `tini` as init process to handle signals properly

### Option 2: Direct Installation

#### Prerequisites

- Go
- Python 3.6+
- Anthropic Claude Desktop app (or Cursor)
- UV (Python package manager), install with `curl -LsSf https://astral.sh/uv/install.sh | sh`
- FFmpeg (_optional_) - Only needed for audio messages. If you want to send audio files as playable WhatsApp voice messages, they must be in `.ogg` Opus format. With FFmpeg installed, the MCP server will automatically convert non-Opus audio files. Without FFmpeg, you can still send raw audio files using the `send_file` tool.

#### Steps

1. **Clone this repository**

   ```bash
   git clone https://github.com/lharries/whatsapp-mcp.git
   cd whatsapp-mcp
   ```

2. **Run the WhatsApp bridge**

   Navigate to the whatsapp-bridge directory and run the Go application:

   ```bash
   cd whatsapp-bridge
   go run main.go
   ```

   The first time you run it, you will be prompted to scan a QR code. Scan the QR code with your WhatsApp mobile app to authenticate.

   After approximately 20 days, you will might need to re-authenticate.

3. **Connect to the MCP server**

   Copy the below json with the appropriate {{PATH}} values:

   ```json
   {
     "mcpServers": {
       "whatsapp": {
         "command": "{{PATH_TO_UV}}", // Run `which uv` and place the output here
         "args": [
           "--directory",
           "{{PATH_TO_SRC}}/whatsapp-mcp/whatsapp-mcp-server", // cd into the repo, run `pwd` and enter the output here + "/whatsapp-mcp-server"
           "run",
           "main.py"
         ]
       }
     }
   }
   ```

   For **Claude**, save this as `claude_desktop_config.json` in your Claude Desktop configuration directory at:

   ```
   ~/Library/Application Support/Claude/claude_desktop_config.json
   ```

   For **Cursor**, save this as `mcp.json` in your Cursor configuration directory at:

   ```
   ~/.cursor/mcp.json
   ```

4. **Restart Claude Desktop / Cursor**

   Open Claude Desktop and you should now see WhatsApp as an available integration.

   Or restart Cursor.

### Windows Compatibility

If you're running this project on Windows, be aware that `go-sqlite3` requires **CGO to be enabled** in order to compile and work properly. By default, **CGO is disabled on Windows**, so you need to explicitly enable it and have a C compiler installed.

#### Steps to get it working:

1. **Install a C compiler**  
   We recommend using [MSYS2](https://www.msys2.org/) to install a C compiler for Windows. After installing MSYS2, make sure to add the `ucrt64\bin` folder to your `PATH`.  
   → A step-by-step guide is available [here](https://code.visualstudio.com/docs/cpp/config-mingw).

2. **Enable CGO and run the app**

   ```bash
   cd whatsapp-bridge
   go env -w CGO_ENABLED=1
   go run main.go
   ```

Without this setup, you'll likely run into errors like:

> `Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work.`

## Architecture Overview

This application consists of two main components:

1. **Go WhatsApp Bridge** (`whatsapp-bridge/`): A Go application that connects to WhatsApp's web API, handles authentication via QR code, and stores message history in SQLite. It serves as the bridge between WhatsApp and the MCP server.
2. **Python MCP Server** (`whatsapp-mcp-server/`): A Python server implementing the Model Context Protocol (MCP), which provides standardized tools for Claude to interact with WhatsApp data and send/receive messages.

### Architecture Diagram

![Architecture Diagram](./architecture.png)

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

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lharries/whatsapp-mcp.git
   cd whatsapp-mcp
   ```
2. **Install prerequisites:**
   - Go (latest stable)
   - Python 3.6+
   - UV (Python package manager):  
     `curl -LsSf https://astral.sh/uv/install.sh | sh`
   - FFmpeg (for audio support)
   - (Windows only) C compiler and enable CGO
3. **Run the Go WhatsApp bridge:**
   ```bash
   cd whatsapp-bridge
   go run main.go
   ```
   - Scan the QR code with your WhatsApp app.
4. **Run the Python MCP server:**
   ```bash
   cd ../whatsapp-mcp-server
   uv venv
   uv pip install -r requirements.txt
   python main.py
   ```
5. **Configure Claude Desktop or Cursor as described in the README.**

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for release history.

## Roadmap

See [roadmap.md](./roadmap.md) for planned features and improvements.

## Usage

Once connected, you can interact with your WhatsApp contacts through Claude, leveraging Claude's AI capabilities in your WhatsApp conversations.

### MCP Tools

Claude can access the following tools to interact with WhatsApp:

- **search_contacts**: Search for contacts by name or phone number
- **list_messages**: Retrieve messages with optional filters and context
- **list_chats**: List available chats with metadata
- **get_chat**: Get information about a specific chat
- **get_direct_chat_by_contact**: Find a direct chat with a specific contact
- **get_contact_chats**: List all chats involving a specific contact
- **get_last_interaction**: Get the most recent message with a contact
- **get_message_context**: Retrieve context around a specific message
- **send_message**: Send a WhatsApp message to a specified phone number or group JID
- **send_file**: Send a file (image, video, raw audio, document) to a specified recipient
- **send_audio_message**: Send an audio file as a WhatsApp voice message (requires the file to be an .ogg opus file or ffmpeg must be installed)
- **download_media**: Download media from a WhatsApp message and get the local file path

### Media Handling Features

The MCP server supports both sending and receiving various media types:

#### Media Sending

You can send various media types to your WhatsApp contacts:

- **Images, Videos, Documents**: Use the `send_file` tool to share any supported media type.
- **Voice Messages**: Use the `send_audio_message` tool to send audio files as playable WhatsApp voice messages.
  - For optimal compatibility, audio files should be in `.ogg` Opus format.
  - With FFmpeg installed, the system will automatically convert other audio formats (MP3, WAV, etc.) to the required format.
  - Without FFmpeg, you can still send raw audio files using the `send_file` tool, but they won't appear as playable voice messages.

#### Media Downloading

By default, just the metadata of the media is stored in the local database. The message will indicate that media was sent. To access this media you need to use the download_media tool which takes the `message_id` and `chat_jid` (which are shown when printing messages containing the meda), this downloads the media and then returns the file path which can be then opened or passed to another tool.

## Technical Details

1. Claude sends requests to the Python MCP server
2. The MCP server queries the Go bridge for WhatsApp data or directly to the SQLite database
3. The Go accesses the WhatsApp API and keeps the SQLite database up to date
4. Data flows back through the chain to Claude
5. When sending messages, the request flows from Claude through the MCP server to the Go bridge and to WhatsApp

## Troubleshooting

- If you encounter permission issues when running uv, you may need to add it to your PATH or use the full path to the executable.
- Make sure both the Go application and the Python server are running for the integration to work properly.

### Authentication Issues

- **QR Code Not Displaying**: If the QR code doesn't appear, try restarting the authentication script. If issues persist, check if your terminal supports displaying QR codes.
- **WhatsApp Already Logged In**: If your session is already active, the Go bridge will automatically reconnect without showing a QR code.
- **Device Limit Reached**: WhatsApp limits the number of linked devices. If you reach this limit, you'll need to remove an existing device from WhatsApp on your phone (Settings > Linked Devices).
- **No Messages Loading**: After initial authentication, it can take several minutes for your message history to load, especially if you have many chats.
- **WhatsApp Out of Sync**: If your WhatsApp messages get out of sync with the bridge, delete both database files (`whatsapp-bridge/store/messages.db` and `whatsapp-bridge/store/whatsapp.db`) and restart the bridge to re-authenticate.

For additional Claude Desktop integration troubleshooting, see the [MCP documentation](https://modelcontextprotocol.io/quickstart/server#claude-for-desktop-integration-issues). The documentation includes helpful tips for checking logs and resolving common issues.

## Database Schema (UML)

Below is a UML diagram of the SQLite data structure used by the WhatsApp bridge:

```plantuml
@startuml
entity chats {
  *jid : TEXT <<PK>>
  name : TEXT
  last_message_time : TIMESTAMP
}

entity messages {
  *id : TEXT
  *chat_jid : TEXT <<FK>>
  sender : TEXT
  content : TEXT
  timestamp : TIMESTAMP
  is_from_me : BOOLEAN
  media_type : TEXT
  filename : TEXT
  url : TEXT
  media_key : BLOB
  file_sha256 : BLOB
  file_enc_sha256 : BLOB
  file_length : INTEGER
}

chats ||--o{ messages : contains
@enduml
```

This diagram shows the relationship between the `chats` and `messages` tables, including primary and foreign keys.

## Running the WhatsApp Bridge (Go)

By default, the WhatsApp bridge starts with its REST API enabled. This REST API is used by the MCP server to send messages and download media.

- **REST API is enabled by default.**
- **Port:** The REST API listens on port `9533` by default. You can change this by setting the `WHATSAPP_BRIDGE_REST_PORT` environment variable.

### Usage Examples

- **Start with REST API (default):**
  ```bash
  go run main.go
  # REST API will be available on port 9533
  ```

- **Change the REST API port:**
  ```bash
  export WHATSAPP_BRIDGE_REST_PORT=9000
  go run main.go
  # REST API will be available on port 9000
  ```

- **Disable the REST API:**
  ```bash
  go run main.go --rest=false
  # REST API will NOT be started
  ```
