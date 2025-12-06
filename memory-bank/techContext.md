# Technical Context

## Technology Stack
- **Engine**: Godot 4.5+
- **Language**: GDScript
- **Plugin Type**: EditorPlugin

## Key Godot 4.5+ APIs
- `Logger` class (custom logger base)
- `OS.add_logger()` / `OS.remove_logger()`
- `EditorPlugin` for dock management
- `EditorSettings` for configuration
- `WebSocketPeer` for streaming
- `EditorInterface.get_script_editor()` for file navigation

## Logger Implementation
```gdscript
class LogStreamLogger extends Logger:
    func _log_message(message: String, error: bool) -> void:
        # Called for print(), print_rich(), etc.
        pass
    
    func _log_error(function: String, file: String, line: int, 
                    code: int, rationale: String, editor_notify: bool,
                    error_type: int, script_backtraces: Array) -> void:
        # Called for push_error(), push_warning(), engine errors
        pass
```

## Configuration (EditorSettings)
| Key | Type | Default |
|-----|------|---------|
| `logstream/max_entries` | int | 2000 |
| `logstream/websocket_url` | string | `ws://127.0.0.1:17865` |
| `logstream/file_log_enabled` | bool | true |
| `logstream/file_log_path` | string | `user://logstream.log` |
| `logstream/start_enabled` | bool | true |

## WebSocket Protocol
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
      "stack": ["..."],
      "project": "MyGodotGame",
      "engine_version": "4.5.stable",
      "session_id": "uuid"
    }
  ]
}
```

## Batching Strategy
- Flush at 50 entries OR 100ms (whichever first)


