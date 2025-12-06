@tool
class_name LogStreamEntry
extends RefCounted
## Represents a single log entry with all metadata.

## Log severity levels
enum Level {
	DEBUG,
	INFO,
	WARNING,
	ERROR,
}

## Log categories
enum Category {
	ENGINE,
	SCRIPT,
	SHADER,
	OTHER,
}

## Unique sequence number for this entry
var seq: int = 0
## ISO 8601 timestamp
var timestamp: String = ""
## Log level
var level: Level = Level.INFO
## The log message
var message: String = ""
## Source file path (res://...)
var file: String = ""
## Line number in source file
var line: int = 0
## Function name where log occurred
var function: String = ""
## Log category
var category: Category = Category.OTHER
## Stack trace frames
var stack: Array[String] = []


static func create_info(msg: String, seq_num: int) -> RefCounted:
	var script: GDScript = load("res://addons/logstream/log_entry.gd")
	var entry: RefCounted = script.new()
	entry.seq = seq_num
	entry.timestamp = _get_iso_timestamp()
	entry.level = Level.INFO
	entry.message = msg
	entry.category = Category.SCRIPT
	return entry


static func create_error(
	msg: String,
	seq_num: int,
	p_function: String,
	p_file: String,
	p_line: int,
	error_type: int,
	backtraces: Array[String]
) -> RefCounted:
	var script: GDScript = load("res://addons/logstream/log_entry.gd")
	var entry: RefCounted = script.new()
	entry.seq = seq_num
	entry.timestamp = _get_iso_timestamp()
	entry.message = msg
	entry.function = p_function
	entry.file = p_file
	entry.line = p_line
	entry.stack = backtraces
	
	# Map Godot's ErrorType to our Level
	match error_type:
		0:  # ERROR_TYPE_ERROR
			entry.level = Level.ERROR
			entry.category = Category.ENGINE
		1:  # ERROR_TYPE_WARNING
			entry.level = Level.WARNING
			entry.category = Category.ENGINE
		2:  # ERROR_TYPE_SCRIPT
			entry.level = Level.ERROR
			entry.category = Category.SCRIPT
		3:  # ERROR_TYPE_SHADER
			entry.level = Level.ERROR
			entry.category = Category.SHADER
		_:
			entry.level = Level.ERROR
			entry.category = Category.OTHER
	
	return entry


static func _get_iso_timestamp() -> String:
	var dt := Time.get_datetime_dict_from_system()
	var msec := Time.get_ticks_msec() % 1000
	return "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ" % [
		dt.year, dt.month, dt.day,
		dt.hour, dt.minute, dt.second, msec
	]


func get_level_string() -> String:
	match level:
		Level.DEBUG: return "debug"
		Level.INFO: return "info"
		Level.WARNING: return "warning"
		Level.ERROR: return "error"
		_: return "info"


func get_level_short() -> String:
	match level:
		Level.DEBUG: return "DBG"
		Level.INFO: return "INF"
		Level.WARNING: return "WRN"
		Level.ERROR: return "ERR"
		_: return "INF"


func get_time_string() -> String:
	# Extract HH:MM:SS from ISO timestamp
	if timestamp.length() >= 19:
		return timestamp.substr(11, 8)
	return "00:00:00"


func to_dict() -> Dictionary:
	return {
		"seq": seq,
		"timestamp": timestamp,
		"level": get_level_string(),
		"message": message,
		"file": file,
		"line": line,
		"function": function,
		"category": _category_to_string(),
		"stack": stack,
		"project": ProjectSettings.get_setting("application/config/name", "Unknown"),
		"engine_version": Engine.get_version_info().string,
		"session_id": _get_session_id(),
	}


func _category_to_string() -> String:
	match category:
		Category.ENGINE: return "engine"
		Category.SCRIPT: return "script"
		Category.SHADER: return "shader"
		_: return "other"


static var _session_id: String = ""

static func _get_session_id() -> String:
	if _session_id.is_empty():
		_session_id = str(randi()) + "-" + str(Time.get_unix_time_from_system())
	return _session_id


