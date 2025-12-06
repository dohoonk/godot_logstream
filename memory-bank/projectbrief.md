# Godot LogStream - Project Brief

## Overview
Godot LogStream is a Godot 4.5+ Editor addon that captures engine logs (errors, warnings, prints), displays them in a dock panel, and streams them externally via WebSocket or file logs.

## Core Requirements
1. **Log Capture**: Use Godot 4.5+ `Logger` API via `OS.add_logger()`
2. **Ring Buffer**: Store last N logs in memory (default 2000)
3. **Dock Panel**: Live stream view with color-coded logs, filters, click-to-copy
4. **File Writer**: Append-mode log file writer
5. **WebSocket Output**: Configurable endpoint with reconnect and batching
6. **Settings**: Configurable via EditorSettings

## Target Platform
- Godot 4.5+
- Editor Plugin (not runtime)
- Asset Library compatible

## Goals
- Capture all engine log types
- Display logs in a color-coded dock
- Write logs to file
- Stream logs over WebSocket with reconnect
- Provide ZIP + Git URL installation
- Meet Asset Library packaging standards


