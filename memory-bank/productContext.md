# Product Context

## Why This Project Exists
Godot's built-in Output panel is limited:
- No filtering by severity
- No external streaming
- No persistent file logging
- No way to programmatically access logs

LogStream solves these problems for developers who need better log management.

## Target Users
- Godot game developers
- Teams needing centralized log collection
- Developers debugging complex issues
- Anyone wanting persistent log files

## User Experience Goals

### Dock Panel
- **Immediate Feedback**: Logs appear in real-time
- **Scannable**: Color-coded by severity
- **Actionable**: Click file paths to jump to code
- **Filterable**: Show only errors, warnings, etc.

### Log Format
```
[15:32:10] [ERR] res://scripts/player.gd:42  Something broke
```
- Compact timestamp (HH:MM:SS)
- Short level tag (INF, WRN, ERR)
- Clickable file:line
- Message preview

### Colors
| Level | Color | Hex |
|-------|-------|-----|
| Error | Red | #ff5555 |
| Warning | Yellow | #ffcc00 |
| Info | Light Gray | #dddddd |
| Debug | Dim Gray | #888888 |

## Key Features
1. **Capture**: All engine + script output via Logger API
2. **Display**: Real-time dock panel with filtering
3. **File**: Persistent log files
4. **Stream**: WebSocket for external tools
5. **Navigate**: Click to open file at line number

## Installation
- ZIP download from Asset Library
- Git clone from GitHub
- Standard Godot addon activation



