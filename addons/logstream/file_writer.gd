@tool
class_name LogStreamFileWriter
extends RefCounted
## Writes log entries to a file in append mode.

const LogEntry := preload("res://addons/logstream/log_entry.gd")

var _file_path: String = "user://logstream.log"
var _enabled: bool = true
var _file: FileAccess
var _mutex := Mutex.new()


func _init(path: String = "user://logstream.log", enabled: bool = true) -> void:
	_file_path = path
	_enabled = enabled
	if _enabled:
		_open_file()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		close()


func set_enabled(enabled: bool) -> void:
	_mutex.lock()
	_enabled = enabled
	if _enabled and not _file:
		_open_file()
	elif not _enabled and _file:
		_close_file()
	_mutex.unlock()


func is_enabled() -> bool:
	return _enabled


func set_path(path: String) -> void:
	_mutex.lock()
	if path != _file_path:
		_close_file()
		_file_path = path
		if _enabled:
			_open_file()
	_mutex.unlock()


func get_path() -> String:
	return _file_path


func write(entry: LogEntry) -> void:
	if not _enabled:
		return
	
	_mutex.lock()
	if not _file:
		_open_file()
	
	if _file:
		var line := _format_entry(entry)
		_file.store_line(line)
		_file.flush()
	_mutex.unlock()


func _format_entry(entry: LogEntry) -> String:
	var parts: Array[String] = [
		"[%s]" % entry.timestamp,
		"[%s]" % entry.get_level_short(),
	]
	
	if not entry.file.is_empty():
		if entry.line > 0:
			parts.append("%s:%d" % [entry.file, entry.line])
		else:
			parts.append(entry.file)
	
	if not entry.function.is_empty():
		parts.append("in %s()" % entry.function)
	
	parts.append(entry.message)
	
	var line := " ".join(parts)
	
	# Add stack trace if present
	if entry.stack.size() > 0:
		line += "\n  Stack:\n"
		for frame in entry.stack:
			line += "    " + frame + "\n"
	
	return line


func _open_file() -> void:
	# Ensure directory exists
	var dir := _file_path.get_base_dir()
	if not dir.is_empty() and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	_file = FileAccess.open(_file_path, FileAccess.WRITE if not FileAccess.file_exists(_file_path) else FileAccess.READ_WRITE)
	if _file:
		_file.seek_end()


func _close_file() -> void:
	if _file:
		_file.close()
		_file = null


func close() -> void:
	_mutex.lock()
	_close_file()
	_mutex.unlock()


func clear_log() -> void:
	_mutex.lock()
	_close_file()
	if FileAccess.file_exists(_file_path):
		DirAccess.remove_absolute(_file_path)
	if _enabled:
		_open_file()
	_mutex.unlock()


