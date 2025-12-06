@tool
extends Control
## LogStream dock panel UI for displaying captured logs.

const LogEntry := preload("res://addons/logstream/log_entry.gd")

const COLOR_ERROR := Color("#ff5555")
const COLOR_WARNING := Color("#ffcc00")
const COLOR_INFO := Color("#dddddd")
const COLOR_DEBUG := Color("#888888")

@onready var log_list: ItemList = %LogList
@onready var search_input: LineEdit = %SearchInput
@onready var filter_errors: CheckButton = %FilterErrors
@onready var filter_warnings: CheckButton = %FilterWarnings
@onready var filter_info: CheckButton = %FilterInfo
@onready var clear_button: Button = %ClearButton
@onready var copy_button: Button = %CopyButton
@onready var status_label: Label = %StatusLabel
@onready var auto_scroll_toggle: CheckButton = %AutoScrollToggle

var _buffer: LogStreamBuffer
var _router: LogStreamRouter
var _auto_scroll: bool = true
var _entries_displayed: Array[LogEntry] = []


func _ready() -> void:
	# Connect UI signals
	search_input.text_changed.connect(_on_search_changed)
	
	# Add test button for debugging
	var test_btn := Button.new()
	test_btn.text = "Test"
	test_btn.tooltip_text = "Add a test log entry"
	test_btn.pressed.connect(_on_test_pressed)
	$VBox/Toolbar.add_child(test_btn)


func _on_test_pressed() -> void:
	# Manually add a test entry to verify display works
	if _buffer:
		var entry: RefCounted = LogEntry.create_info("[LogStream] Test entry at " + Time.get_time_string_from_system(), _buffer.get_count() + 1)
		_buffer.add(entry)
		print("[LogStream] Test entry added. Buffer count: ", _buffer.get_count())
	filter_errors.toggled.connect(_on_filter_changed)
	filter_warnings.toggled.connect(_on_filter_changed)
	filter_info.toggled.connect(_on_filter_changed)
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	auto_scroll_toggle.toggled.connect(_on_auto_scroll_toggled)
	log_list.item_clicked.connect(_on_item_clicked)
	log_list.item_activated.connect(_on_item_activated)
	
	# Set defaults
	filter_errors.button_pressed = true
	filter_warnings.button_pressed = true
	filter_info.button_pressed = true
	auto_scroll_toggle.button_pressed = true


func setup(buffer: LogStreamBuffer, router: LogStreamRouter) -> void:
	_buffer = buffer
	_router = router
	
	# Connect to buffer signals
	_buffer.entry_added.connect(_on_entry_added)
	_buffer.entries_dropped.connect(_on_entries_dropped)
	
	# Initial refresh
	_refresh_list()


func _on_entry_added(entry: LogEntry) -> void:
	if _should_show_entry(entry):
		_add_entry_to_list(entry)
		if _auto_scroll:
			log_list.ensure_current_is_visible()
	_update_status()


func _on_entries_dropped(count: int) -> void:
	# Refresh to remove dropped entries from display
	call_deferred("_refresh_list")


func _should_show_entry(entry: LogEntry) -> bool:
	# Check level filters
	match entry.level:
		LogEntry.Level.ERROR:
			if not filter_errors.button_pressed:
				return false
		LogEntry.Level.WARNING:
			if not filter_warnings.button_pressed:
				return false
		LogEntry.Level.INFO, LogEntry.Level.DEBUG:
			if not filter_info.button_pressed:
				return false
	
	# Check search text
	var search_text := search_input.text.strip_edges()
	if not search_text.is_empty():
		var text_lower := search_text.to_lower()
		var matches := (
			entry.message.to_lower().contains(text_lower) or
			entry.file.to_lower().contains(text_lower) or
			entry.function.to_lower().contains(text_lower)
		)
		if not matches:
			return false
	
	return true


func _add_entry_to_list(entry: LogEntry) -> void:
	var text := _format_entry_for_display(entry)
	var idx := log_list.add_item(text)
	
	# Set color based on level
	var color := _get_color_for_level(entry.level)
	log_list.set_item_custom_fg_color(idx, color)
	
	# Store entry reference
	log_list.set_item_metadata(idx, entry)
	_entries_displayed.append(entry)


func _format_entry_for_display(entry: LogEntry) -> String:
	var parts: Array[String] = [
		"[%s]" % entry.get_time_string(),
		"[%s]" % entry.get_level_short(),
	]
	
	if not entry.file.is_empty():
		if entry.line > 0:
			parts.append("%s:%d" % [entry.file, entry.line])
		else:
			parts.append(entry.file)
	
	# Truncate long messages for display (first line only)
	var msg := entry.message.split("\n")[0]
	if msg.length() > 200:
		msg = msg.substr(0, 197) + "..."
	parts.append(msg)
	
	return "  ".join(parts)


func _get_color_for_level(level: LogEntry.Level) -> Color:
	match level:
		LogEntry.Level.ERROR:
			return COLOR_ERROR
		LogEntry.Level.WARNING:
			return COLOR_WARNING
		LogEntry.Level.DEBUG:
			return COLOR_DEBUG
		_:
			return COLOR_INFO


func _refresh_list() -> void:
	if not log_list:
		return
	
	log_list.clear()
	_entries_displayed.clear()
	
	if not _buffer:
		return
	
	# Get filtered entries
	var levels: Array[LogEntry.Level] = []
	if filter_errors.button_pressed:
		levels.append(LogEntry.Level.ERROR)
	if filter_warnings.button_pressed:
		levels.append(LogEntry.Level.WARNING)
	if filter_info.button_pressed:
		levels.append(LogEntry.Level.INFO)
		levels.append(LogEntry.Level.DEBUG)
	
	var entries := _buffer.get_entries_filtered(levels, search_input.text.strip_edges())
	
	for entry in entries:
		_add_entry_to_list(entry)
	
	if _auto_scroll and log_list.item_count > 0:
		log_list.select(log_list.item_count - 1)
		log_list.ensure_current_is_visible()
	
	_update_status()


func _update_status() -> void:
	if not _buffer:
		status_label.text = "No buffer"
		return
	
	var total := _buffer.get_count()
	var shown := log_list.item_count
	status_label.text = "%d / %d logs" % [shown, total]


func _on_search_changed(_new_text: String) -> void:
	_refresh_list()


func _on_filter_changed(_pressed: bool) -> void:
	_refresh_list()


func _on_clear_pressed() -> void:
	if _buffer:
		_buffer.clear()
	_refresh_list()


func _on_copy_pressed() -> void:
	var selected := log_list.get_selected_items()
	if selected.is_empty():
		return
	
	var texts: Array[String] = []
	for idx in selected:
		var entry: LogEntry = log_list.get_item_metadata(idx)
		if entry:
			texts.append(_format_entry_for_copy(entry))
	
	DisplayServer.clipboard_set("\n".join(texts))


func _format_entry_for_copy(entry: LogEntry) -> String:
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
	
	var text := " ".join(parts)
	
	# Add stack trace
	if entry.stack.size() > 0:
		text += "\nStack:\n"
		for frame in entry.stack:
			text += "  " + frame + "\n"
	
	return text


func _on_auto_scroll_toggled(pressed: bool) -> void:
	_auto_scroll = pressed


func _on_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	# Show tooltip with full info
	var entry: LogEntry = log_list.get_item_metadata(index)
	if entry:
		log_list.set_item_tooltip(index, _format_entry_for_copy(entry))


func _on_item_activated(index: int) -> void:
	# Double-click: open file at line
	var entry: LogEntry = log_list.get_item_metadata(index)
	if entry and not entry.file.is_empty():
		_open_script_at_line(entry.file, entry.line)


func _open_script_at_line(file_path: String, line: int) -> void:
	if file_path.is_empty():
		return
	
	# Check if file exists
	if not ResourceLoader.exists(file_path):
		push_warning("[LogStream] File not found: %s" % file_path)
		return
	
	# Load the script
	var script := load(file_path)
	if script is Script:
		var script_editor := EditorInterface.get_script_editor()
		EditorInterface.edit_script(script, line, 0)
		EditorInterface.set_main_screen_editor("Script")


