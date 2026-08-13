class_name ConsoleServiceClient
extends ConsoleHandler

const LOG_TAG: String = "GTerm Service"

var console_manager: Node

var _owner: WebSocketPeer
var _initialized := false


func _init(peer: WebSocketPeer) -> void:
	_owner = peer


func get_peer() -> WebSocketPeer:
	return _owner


func is_initialized() -> bool:
	return _initialized


func mark_initialized() -> void:
	if _initialized:
		return

	_initialized = true

	print("GTERM Web client connected!")


func run_from_remote(command_full: String) -> void:
	var commands = _split_commands(command_full)

	for cmd in commands:
		var tokens = _tokenize_command(cmd)

		await _process_command(self, tokens)

	print_remote("\n")


func remote_log(log_tag: String, output: String, color: String = "") -> void:
	var message := strip_output(output)
	if not color.is_empty():
		message = "[color=%s]%s[/color]" % [color, message]

	var line := "[%s] %s" % [log_tag.to_upper(), message]

	print_remote(line + "\n")


func strip_output(output: String) -> String:
	output = output.replace("[i]", "")
	output = output.replace("[/i]", "")

	return output


func print_remote(output: String) -> void:
	if _owner == null:
		return

	if _owner.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return

	_owner.send_text(output)


func log_rainbow(log_tag: String, output: String) -> void:
	remote_log(log_tag, output, "rainbow")


func log_info(log_tag: String, output: String) -> void:
	remote_log(log_tag, output, "normal")


func log_warn(log_tag: String, output: String) -> void:
	remote_log(log_tag, output, "warn")


func log_error(log_tag: String, output: String) -> void:
	remote_log(log_tag, output, "error")


func _exit_tree() -> void:
	if _owner == null:
		return

	if _owner.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_owner.close(1000, "Client disconnected")

	_owner = null

	print("GTERM Web client disconnected")
