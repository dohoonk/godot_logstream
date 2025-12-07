# LogStream

A Godot 4.5+ Editor addon that captures engine logs, displays them in a dock panel, and streams them via WebSocket or file.

## Features

- **Log Capture**: Captures all engine output using Godot 4.5+ Logger API
  - `print()`, `print_rich()`, `print_error()`
  - `push_error()`, `push_warning()`
  - Script errors with stack traces
  - Shader errors

- **Dock Panel**: Real-time log viewer in the editor
  - Color-coded by severity (Error, Warning, Info)
  - Filter by log level
  - Search across messages, files, and functions
  - Click to copy
  - Double-click file paths to open script at line

- **File Logging**: Persistent log files
  - Append mode
  - Configurable path
  - Full timestamps and stack traces

- **WebSocket Streaming**: External log access
  - Configurable endpoint
  - Auto-reconnect
  - Batched JSON messages

## Requirements

- **Godot 4.5+** (uses the new Logger API)

## Installation

### From Asset Library
1. Search for "LogStream" in the Godot Asset Library
2. Click Install

### From GitHub
1. Download or clone this repository
2. Copy the `addons/logstream/` folder to your project's `addons/` directory
3. Enable the plugin in Project Settings → Plugins

## Configuration

Settings are stored in Editor Settings under the `logstream/` prefix:

| Setting | Default | Description |
|---------|---------|-------------|
| `max_entries` | 2000 | Maximum logs in memory (500-10000) |
| `websocket_url` | `ws://127.0.0.1:17865` | WebSocket server URL |
| `file_log_enabled` | true | Enable file logging |
| `file_log_path` | `user://logstream.log` | Log file path |
| `start_enabled` | true | Auto-enable on startup |

## WebSocket Protocol

LogStream sends batched JSON messages:

```json
{
  "type": "log_batch",
  "logs": [
    {
      "seq": 1234,
      "timestamp": "2025-12-04T15:32:10.123Z",
      "level": "error",
      "message": "Something broke",
      "file": "res://scripts/player.gd",
      "line": 42,
      "function": "_physics_process",
      "category": "script",
      "stack": ["res://scripts/player.gd:42 in _physics_process"],
      "project": "MyGame",
      "engine_version": "4.5.stable",
      "session_id": "abc123"
    }
  ]
}
```

### Log Levels
- `error` - Errors and script exceptions
- `warning` - Warnings
- `info` - Print statements
- `debug` - Debug messages

### Categories
- `engine` - Engine errors/warnings
- `script` - Script errors
- `shader` - Shader errors
- `other` - Other messages

## Usage

### Dock Panel
The LogStream panel appears in the bottom panel (next to Output). Features:

- **Search**: Type to filter logs by message, file, or function
- **ERR/WRN/INF**: Toggle visibility of each log level
- **Auto**: Enable/disable auto-scroll to newest
- **Copy**: Copy selected log entries to clipboard
- **Clear**: Clear all logs

### Double-Click to Navigate
Double-click any log entry with a file path to open the script at that line.

## License

MIT License



