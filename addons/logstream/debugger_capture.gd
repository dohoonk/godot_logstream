@tool
extends EditorDebuggerPlugin
## Captures logs from running game via debugger connection.
## The game must send messages using EngineDebugger.send_message("logstream:log", [...])

const LogEntry := preload("res://addons/logstream/log_entry.gd")

signal log_captured(entry: LogEntry)

var _seq_counter: int = 0


func _has_capture(capture: String) -> bool:
	return capture == "logstream"


func _capture(message: String, data: Array, session_id: int) -> bool:
	if message == "logstream:log" and data.size() >= 2:
		var level_str: String = str(data[0])
		var msg: String = str(data[1])
		
		var level: int = LogEntry.Level.INFO
		match level_str:
			"error":
				level = LogEntry.Level.ERROR
			"warning":
				level = LogEntry.Level.WARNING
			"debug":
				level = LogEntry.Level.DEBUG
		
		_emit_log(msg, level)
		return true
	
	return false


func _emit_log(text: String, level: int) -> void:
	if text.strip_edges().is_empty():
		return
	
	_seq_counter += 1
	var entry: RefCounted = LogEntry.create_info(text, _seq_counter)
	entry.level = level
	log_captured.emit(entry)


func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	session.started.connect(_on_session_started.bind(session_id))
	session.stopped.connect(_on_session_stopped.bind(session_id))


func _on_session_started(session_id: int) -> void:
	_emit_log("[LogStream] Game started (session %d)" % session_id, LogEntry.Level.INFO)


func _on_session_stopped(session_id: int) -> void:
	_emit_log("[LogStream] Game stopped (session %d)" % session_id, LogEntry.Level.INFO)
