class_name ConsoleServiceClient
extends ConsoleHandler
const LOG_TAG: String = "GTerm Service"
var _owner: StreamPeerTCP = null


func _init(peer: StreamPeerTCP) -> void:
	_owner = peer
	print("Remote: Client connected! - %s" % peer.get_connected_host())


func get_peer() -> StreamPeerTCP:
	return _owner


func run_from_remote(command_full: String) -> void:
	var commands = _split_commands(command_full)
	for cmd in commands:
		var tokens = _tokenize_command(cmd)
		await _process_command(self, tokens)

	print_remote("\r\n")
	print_remote("> ")


func remote_log(log_tag: String, output: String) -> void:
	var line: String = "[%s] %s" % [log_tag.to_upper(), strip_output(output)]
	print_remote(line + "\r\n")


func strip_output(output: String) -> String:
	output = output.replace("[i]", "")
	output = output.replace("[/i]", "")
	return output


func print_remote(output: String) -> void:
	var bytes = output.to_utf8_buffer()
	_owner.put_data(bytes)


func log_rainbow(log_tag: String, output: String) -> void:
	remote_log(log_tag, output)


func log_info(log_tag: String, output: String) -> void:
	remote_log(log_tag, output)


func log_warn(log_tag: String, output: String) -> void:
	remote_log(log_tag, output)


func log_error(log_tag: String, output: String) -> void:
	remote_log(log_tag, output)


func _exit_tree() -> void:
	if _owner:
		if _owner.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			_owner.disconnect_from_host()
			_owner = null
		print("Remote: Client disconnected")
