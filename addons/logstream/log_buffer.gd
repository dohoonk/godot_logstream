@tool
class_name LogStreamBuffer
extends RefCounted
## Ring buffer for storing log entries with a fixed capacity.

const LogEntry := preload("res://addons/logstream/log_entry.gd")

## Emitted when a new entry is added
signal entry_added(entry: LogEntry)

## Emitted when entries are dropped due to buffer overflow
signal entries_dropped(count: int)

const MIN_CAPACITY := 500
const MAX_CAPACITY := 10000
const DEFAULT_CAPACITY := 2000

var _entries: Array[LogEntry] = []
var _capacity: int = DEFAULT_CAPACITY
var _mutex := Mutex.new()


func _init(capacity: int = DEFAULT_CAPACITY) -> void:
	set_capacity(capacity)


func set_capacity(new_capacity: int) -> void:
	_mutex.lock()
	_capacity = clampi(new_capacity, MIN_CAPACITY, MAX_CAPACITY)
	_trim_to_capacity()
	_mutex.unlock()


func get_capacity() -> int:
	return _capacity


func add(entry: LogEntry) -> void:
	_mutex.lock()
	_entries.append(entry)
	var dropped := _trim_to_capacity()
	_mutex.unlock()
	
	if dropped > 0:
		entries_dropped.emit(dropped)
	entry_added.emit(entry)


func _trim_to_capacity() -> int:
	## Returns number of entries dropped. Must be called with mutex locked.
	var dropped := 0
	while _entries.size() > _capacity:
		_entries.pop_front()
		dropped += 1
	return dropped


func get_entries() -> Array[LogEntry]:
	_mutex.lock()
	var copy: Array[LogEntry] = _entries.duplicate()
	_mutex.unlock()
	return copy


func get_entries_filtered(
	levels: Array[LogEntry.Level] = [],
	search_text: String = ""
) -> Array[LogEntry]:
	_mutex.lock()
	var result: Array[LogEntry] = []
	
	for entry in _entries:
		# Filter by level
		if levels.size() > 0 and not levels.has(entry.level):
			continue
		
		# Filter by search text
		if not search_text.is_empty():
			var text_lower := search_text.to_lower()
			var matches := (
				entry.message.to_lower().contains(text_lower) or
				entry.file.to_lower().contains(text_lower) or
				entry.function.to_lower().contains(text_lower)
			)
			if not matches:
				continue
		
		result.append(entry)
	
	_mutex.unlock()
	return result


func get_count() -> int:
	_mutex.lock()
	var count := _entries.size()
	_mutex.unlock()
	return count


func clear() -> void:
	_mutex.lock()
	_entries.clear()
	_mutex.unlock()


func get_last(count: int) -> Array[LogEntry]:
	_mutex.lock()
	var start_idx := maxi(0, _entries.size() - count)
	var result: Array[LogEntry] = _entries.slice(start_idx)
	_mutex.unlock()
	return result


