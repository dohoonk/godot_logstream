@tool
extends EditorPlugin
## Main LogStream plugin entry point.

const AUTOLOAD_NAME := "LogStreamCapture"
const DOCK_NAME := "LogStream"
const LogEntry := preload("res://addons/logstream/log_entry.gd")
const DebuggerCapture := preload("res://addons/logstream/debugger_capture.gd")

var _capture: LogStreamCapture
var _buffer: LogStreamBuffer
var _file_writer: LogStreamFileWriter
var _websocket: LogStreamWebSocket
var _dock_panel: Control
var _debugger: EditorDebuggerPlugin


func _enter_tree() -> void:
	# Load settings
	_init_settings()
	
	# Initialize components
	_buffer = LogStreamBuffer.new(_get_setting("max_entries", 2000))
	
	# Create capture for editor logs (Logger API)
	_capture = LogStreamCapture.new()
	_capture.name = AUTOLOAD_NAME
	add_child(_capture)
	
	# Connect capture to buffer
	_capture.log_captured.connect(_on_log_captured)
	
	# Create debugger plugin for runtime logs
	_debugger = DebuggerCapture.new()
	_debugger.log_captured.connect(_on_log_captured)
	add_debugger_plugin(_debugger)
	
	# Create file writer
	if _get_setting("file_log_enabled", true):
		_file_writer = LogStreamFileWriter.new(
			_get_setting("file_log_path", "user://logstream.log"),
			true
		)
	
	# Create websocket client
	_websocket = LogStreamWebSocket.new(_get_setting("websocket_url", "ws://127.0.0.1:17865"))
	
	# Create and add dock panel
	var dock_scene := preload("res://addons/logstream/dock_panel.tscn")
	_dock_panel = dock_scene.instantiate()
	_dock_panel.setup(_buffer, null)
	add_control_to_bottom_panel(_dock_panel, DOCK_NAME)
	
	# Start websocket if enabled
	if _get_setting("start_enabled", true):
		_websocket.set_enabled(true)


func _exit_tree() -> void:
	# Clean up debugger plugin
	if _debugger:
		remove_debugger_plugin(_debugger)
		_debugger = null
	
	# Clean up dock panel
	if _dock_panel:
		remove_control_from_bottom_panel(_dock_panel)
		_dock_panel.queue_free()
		_dock_panel = null
	
	# Clean up websocket
	if _websocket:
		_websocket.disconnect_from_server()
		_websocket = null
	
	# Clean up file writer
	if _file_writer:
		_file_writer.close()
		_file_writer = null
	
	# Clean up capture
	if _capture:
		remove_child(_capture)
		_capture.queue_free()
		_capture = null
	
	_buffer = null


func _on_log_captured(entry: LogEntry) -> void:
	# Route to buffer
	_buffer.add(entry)
	
	# Route to file writer
	if _file_writer and _file_writer.is_enabled():
		_file_writer.write(entry)
	
	# Route to websocket
	if _websocket and _websocket.is_connected_to_server():
		_websocket.queue_entry(entry)


func _process(delta: float) -> void:
	# Poll websocket for updates
	if _websocket and _websocket.is_enabled():
		_websocket.poll(delta)


func _init_settings() -> void:
	var es := EditorInterface.get_editor_settings()
	
	_add_setting(es, "logstream/max_entries", TYPE_INT, 2000, PROPERTY_HINT_RANGE, "500,10000,1")
	_add_setting(es, "logstream/websocket_url", TYPE_STRING, "ws://127.0.0.1:17865")
	_add_setting(es, "logstream/file_log_enabled", TYPE_BOOL, true)
	_add_setting(es, "logstream/file_log_path", TYPE_STRING, "user://logstream.log")
	_add_setting(es, "logstream/start_enabled", TYPE_BOOL, true)


func _add_setting(es: EditorSettings, name: String, type: int, default_value: Variant, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	if not es.has_setting(name):
		es.set_setting(name, default_value)
	es.set_initial_value(name, default_value, false)
	
	var info := {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	}
	es.add_property_info(info)


func _get_setting(key: String, default_value: Variant) -> Variant:
	var es := EditorInterface.get_editor_settings()
	var full_key := "logstream/" + key
	if es.has_setting(full_key):
		return es.get_setting(full_key)
	return default_value


## Public API

func get_buffer() -> LogStreamBuffer:
	return _buffer

func get_capture() -> LogStreamCapture:
	return _capture

func get_websocket() -> LogStreamWebSocket:
	return _websocket

func get_file_writer() -> LogStreamFileWriter:
	return _file_writer
