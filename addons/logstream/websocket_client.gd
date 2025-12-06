@tool
class_name LogStreamWebSocket
extends RefCounted
## WebSocket client for streaming log entries with batching and auto-reconnect.

const LogEntry := preload("res://addons/logstream/log_entry.gd")

signal connected()
signal disconnected()
signal error(message: String)

const BATCH_SIZE := 50
const FLUSH_INTERVAL_MS := 100
const RECONNECT_DELAY_SEC := 5.0

var _url: String = "ws://127.0.0.1:17865"
var _socket: WebSocketPeer
var _enabled: bool = false
var _queue: Array[LogEntry] = []
var _mutex := Mutex.new()
var _last_flush_time: int = 0
var _reconnect_timer: float = 0.0
var _should_reconnect: bool = false


func _init(url: String = "ws://127.0.0.1:17865") -> void:
	_url = url
	_socket = WebSocketPeer.new()


func set_url(url: String) -> void:
	if url != _url:
		_url = url
		if _enabled:
			disconnect_from_server()
			connect_to_server()


func get_url() -> String:
	return _url


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _enabled:
		connect_to_server()
	else:
		disconnect_from_server()


func is_enabled() -> bool:
	return _enabled


func connect_to_server() -> Error:
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close()
	
	_should_reconnect = true
	var err := _socket.connect_to_url(_url)
	if err != OK:
		error.emit("Failed to connect to %s: %s" % [_url, error_string(err)])
		return err
	
	return OK


func disconnect_from_server() -> void:
	_should_reconnect = false
	_socket.close()
	disconnected.emit()


func is_connected_to_server() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN


func queue_entry(entry: LogEntry) -> void:
	if not _enabled:
		return
	
	_mutex.lock()
	_queue.append(entry)
	
	# Check if we should flush
	var should_flush := false
	var now := Time.get_ticks_msec()
	
	if _queue.size() >= BATCH_SIZE:
		should_flush = true
	elif now - _last_flush_time >= FLUSH_INTERVAL_MS:
		should_flush = true
	
	if should_flush and is_connected_to_server():
		_flush_queue()
	
	_mutex.unlock()


func _flush_queue() -> void:
	## Must be called with mutex locked
	if _queue.is_empty():
		return
	
	var logs: Array[Dictionary] = []
	for entry in _queue:
		logs.append(entry.to_dict())
	
	var payload := {
		"type": "log_batch",
		"logs": logs,
	}
	
	var json := JSON.stringify(payload)
	_socket.send_text(json)
	
	_queue.clear()
	_last_flush_time = Time.get_ticks_msec()


func poll(delta: float) -> void:
	## Call this from _process to handle WebSocket updates
	_socket.poll()
	
	var state := _socket.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_OPEN:
			_reconnect_timer = 0.0
			# Check for time-based flush
			_mutex.lock()
			var now := Time.get_ticks_msec()
			if not _queue.is_empty() and now - _last_flush_time >= FLUSH_INTERVAL_MS:
				_flush_queue()
			_mutex.unlock()
			
			# Process incoming messages (if any)
			while _socket.get_available_packet_count() > 0:
				var _packet := _socket.get_packet()
				# We don't expect responses, but drain the buffer
		
		WebSocketPeer.STATE_CLOSING:
			pass  # Wait for close
		
		WebSocketPeer.STATE_CLOSED:
			if _should_reconnect and _enabled:
				_reconnect_timer += delta
				if _reconnect_timer >= RECONNECT_DELAY_SEC:
					_reconnect_timer = 0.0
					connect_to_server()
		
		WebSocketPeer.STATE_CONNECTING:
			pass  # Wait for connection


func flush_now() -> void:
	## Force flush the queue immediately
	_mutex.lock()
	if is_connected_to_server():
		_flush_queue()
	_mutex.unlock()


func get_queue_size() -> int:
	_mutex.lock()
	var size := _queue.size()
	_mutex.unlock()
	return size


