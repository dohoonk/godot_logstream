@tool
class_name LogStreamCapture
extends Node
## Autoload that captures all engine logs using Godot 4.5+ Logger API.

const LogEntry := preload("res://addons/logstream/log_entry.gd")

## Emitted when a new log entry is captured
signal log_captured(entry: LogEntry)

var _logger: _LogStreamLogger
var _seq_counter: int = 0
var _mutex := Mutex.new()
var _debug_count: int = 0


func _ready() -> void:
	# Register logger when node is ready (in scene tree)
	if not _logger:
		_logger = _LogStreamLogger.new(self)
		OS.add_logger(_logger)


func _exit_tree() -> void:
	if _logger:
		OS.remove_logger(_logger)
		_logger = null


func _get_next_seq() -> int:
	_mutex.lock()
	_seq_counter += 1
	var seq := _seq_counter
	_mutex.unlock()
	return seq


func _on_message(message: String, is_error: bool) -> void:
	_debug_count += 1
	var entry := LogEntry.create_info(message, _get_next_seq())
	if is_error:
		entry.level = LogEntry.Level.ERROR
	log_captured.emit(entry)


func _on_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	editor_notify: bool,
	error_type: int,
	backtraces: Array[String]
) -> void:
	_debug_count += 1
	var entry := LogEntry.create_error(
		rationale if not rationale.is_empty() else code,
		_get_next_seq(),
		function,
		file,
		line,
		error_type,
		backtraces
	)
	log_captured.emit(entry)


func get_debug_count() -> int:
	return _debug_count


## Inner class that extends Logger
class _LogStreamLogger extends Logger:
	var _capture: LogStreamCapture
	var _msg_count: int = 0
	var _err_count: int = 0
	
	func _init(capture: LogStreamCapture) -> void:
		_capture = capture
	
	func _log_message(message: String, error: bool) -> void:
		_msg_count += 1
		if _capture and is_instance_valid(_capture):
			_capture.call_deferred("_on_message", message, error)
	
	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
	) -> void:
		_err_count += 1
		if not _capture or not is_instance_valid(_capture):
			return
		
		# Convert ScriptBacktrace array to string array
		var backtraces: Array[String] = []
		for bt in script_backtraces:
			if bt:
				var bt_str := str(bt)
				if not bt_str.is_empty():
					backtraces.append(bt_str)
		
		_capture.call_deferred(
			"_on_error",
			function,
			file,
			line,
			code,
			rationale,
			editor_notify,
			error_type,
			backtraces
		)
