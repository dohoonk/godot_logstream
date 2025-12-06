@tool
class_name LogStreamRouter
extends RefCounted
## Routes log entries from capture to all registered sinks (buffer, file, websocket, UI).

const LogEntry := preload("res://addons/logstream/log_entry.gd")

var _buffer: LogStreamBuffer
var _capture: LogStreamCapture
var _file_writer: LogStreamFileWriter
var _websocket: LogStreamWebSocket

## Reference to dock panel for UI updates (set by plugin)
var dock_panel: Control


func _init(capture: LogStreamCapture, buffer: LogStreamBuffer) -> void:
	_capture = capture
	_buffer = buffer
	
	# Connect to capture signal
	_capture.log_captured.connect(_on_log_captured)


func set_file_writer(writer: LogStreamFileWriter) -> void:
	_file_writer = writer


func set_websocket(ws: LogStreamWebSocket) -> void:
	_websocket = ws


func _on_log_captured(entry: LogEntry) -> void:
	# Route to buffer (always)
	_buffer.add(entry)
	
	# Route to file writer
	if _file_writer and _file_writer.is_enabled():
		_file_writer.write(entry)
	
	# Route to websocket
	if _websocket and _websocket.is_connected_to_server():
		_websocket.queue_entry(entry)
	
	# Route to UI (dock panel handles its own updates via buffer signal)


func get_buffer() -> LogStreamBuffer:
	return _buffer


func get_capture() -> LogStreamCapture:
	return _capture


