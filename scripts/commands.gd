class_name Commands
extends RefCounted

static var _registered_commands: Dictionary = {}


#region Public
static func register(
	command_name: String,
	command_arguments: Dictionary,
	command_action: Callable,
	description: String = "",
	hidden: bool = false
) -> void:
	var arg_list: Array = []

	for name in command_arguments.keys():
		arg_list.append(Argument.new(name, command_arguments[name]))

	_registered_commands[command_name] = RegisteredCommand.new(
		arg_list, command_action, description, hidden
	)

	Console.on_register_command.emit()


static func get_commands() -> Dictionary:
	return _registered_commands


#endregion


#region Built-in commands
static func register_all() -> void:
	register("/sleep", {"time": TYPE_FLOAT}, cmd_sleep, "Sleeps for a given time")
	register(
		"/exec", {"file_name": TYPE_STRING}, cmd_exec, "Executes a .cfg file containing commands"
	)
	register("/load-mod", {"file_name": TYPE_STRING}, cmd_load_mod, "Loads a .pck mod file")
	register(
		"/load-script",
		{"file_name": TYPE_STRING},
		cmd_load_script,
		"Loads a .gd script and executes its 'run' function"
	)
	register("/clear", {}, cmd_clear, "Clears console logs")
	register("/pause", {"pause": TYPE_BOOL}, cmd_pause, "Pauses and unpauses the game")
	register("/game-speed", {"time": TYPE_FLOAT}, cmd_game_speed, "Sets the current game speed")
	register("/fps-cap", {"cap": TYPE_INT}, cmd_fps_cap, "Limits the max game framerate")
	register("/vsync", {"state": TYPE_BOOL}, cmd_vsync_mode, "Turns vsync on and off")
	register("/monitor-info", {}, cmd_monitor_info, "Prints machine monitor info")
	register("/stats", {}, cmd_stats, "Prints game performance related stats")
	register("/net-stats", {}, cmd_network, "Prints network related stats")
	register("/print", {"text": TYPE_STRING}, cmd_print, "Prints words into the console")
	register("/help", {}, cmd_help, "Lists the available commands")


static func cmd_sleep(handler: ConsoleHandler, args: Dictionary) -> void:
	await handler.get_tree().create_timer(args["time"]).timeout


static func cmd_exec(handler: ConsoleHandler, args: Dictionary) -> void:
	var code = _read_file(args["file_name"])
	if code == "":
		handler.log_error("console", "File not found or invalid!")
		return
	handler.run(handler, code)


static func cmd_load_mod(handler: ConsoleHandler, args: Dictionary) -> void:
	var mod_file = ProjectSettings.globalize_path(args.get("file_name", ""))
	if mod_file == "" or not FileAccess.file_exists(mod_file):
		handler.log_warn("PCKLoader", "PCK file not found: %s" % mod_file)
		return
	if ProjectSettings.load_resource_pack(mod_file):
		handler.log_info("PCKLoader", "Successfully loaded: %s" % mod_file)
	else:
		handler.log_error("PCKLoader", "Failed to load PCK: %s" % mod_file)


static func cmd_load_script(handler: ConsoleHandler, args: Dictionary) -> void:
	var script_code = _read_file(args["file_name"])
	if script_code == "":
		handler.log_error("console", "File not found or invalid!")
		return
	handler.log_info("console", "Compiling %s..." % args["file_name"])
	_run_text_script(handler, script_code)


static func cmd_clear(handler: ConsoleHandler, _args: Dictionary = {}) -> void:
	handler.log_clear()


static func cmd_pause(handler: ConsoleHandler, args: Dictionary) -> void:
	var pause: bool = args.get("pause", true)
	Engine.time_scale = 0.0 if pause else 1.0
	handler.log_info("console", "Game paused: %s" % str(pause))


static func cmd_fps_cap(handler: ConsoleHandler, args: Dictionary) -> void:
	var cap: int = args.get("cap", 60)
	Engine.max_fps = cap
	handler.log_info("console", "Game max fps cap set to %d fps" % cap)


static func cmd_vsync_mode(handler: ConsoleHandler, args: Dictionary) -> void:
	var state: bool = args.get("state", false)
	if state:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	handler.log_info("console", "Game vsync: %s" % str(state))


static func cmd_monitor_info(handler: ConsoleHandler, _args: Dictionary = {}) -> void:
	var monitor_count = DisplayServer.get_screen_count()

	for screen_index in range(monitor_count):
		var resolution = DisplayServer.screen_get_size(screen_index)
		var refresh_rate = DisplayServer.screen_get_refresh_rate(screen_index)
		var dpi = DisplayServer.screen_get_dpi(screen_index)

		handler.log_info("console", "Monitor %d info:" % screen_index)
		handler.log_info("console", "  Resolution: %dx%d" % [resolution.x, resolution.y])
		handler.log_info("console", "  Refresh Rate: %d Hz" % refresh_rate)
		handler.log_info("console", "  DPI: %d" % dpi)
		handler.log_info("console", "--------------------------------")


static func cmd_game_speed(handler: ConsoleHandler, args: Dictionary) -> void:
	var time: float = args.get("time", 1.0)
	Engine.time_scale = time
	handler.log_info("console", "Game speed set to: %s" % str(Engine.time_scale))


static func cmd_stats(handler: ConsoleHandler) -> void:
	handler.log_info("console", "Current FPS: %s" % str(Engine.get_frames_per_second()))
	var size = DisplayServer.window_get_size()
	handler.log_info("console", "Current resolution: %dx%d" % [size.x, size.y])


static func cmd_network(handler: ConsoleHandler, _args: Dictionary = {}) -> void:
	handler.log_info("console", "Machine network address: %s" % get_local_ip())


static func cmd_print(handler: ConsoleHandler, args: Dictionary) -> void:
	handler.log_info("console", args["text"])


static func cmd_help(handler: ConsoleHandler, _args: Dictionary = {}) -> void:
	var registered_commands := get_commands()
	var visible_command_names: Array[String] = []

	for command_name: String in registered_commands:
		var command: RegisteredCommand = registered_commands[command_name]
		if not command.hidden:
			visible_command_names.append(command_name)

	if visible_command_names.is_empty():
		handler.log_error("console", "No commands available.")
		return

	visible_command_names.sort()
	handler.log_rainbow("console", "Available commands (%d):" % visible_command_names.size())

	for command_name: String in visible_command_names:
		var command: RegisteredCommand = registered_commands[command_name]
		var command_info := "  %s" % _format_command_usage(command_name, command)
		if not command.description.is_empty():
			command_info += " - %s" % command.description
		handler.log_info("console", command_info)


#endregion


#region Helpers
static func _format_command_usage(command_name: String, command: RegisteredCommand) -> String:
	var usage := command_name
	for argument: Argument in command.arguments:
		usage += " <%s:%s>" % [argument.argument_name, type_string(argument.value_type).to_lower()]
	return usage


static func _read_file(relative_path: String) -> String:
	if relative_path.is_empty():
		return ""
	var file_path = _resolve_file_path(relative_path)
	if file_path.is_empty():
		return ""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	file.close()
	return content


static func _resolve_file_path(relative_path: String) -> String:
	if not OS.has_feature("editor"):
		var executable_path = OS.get_executable_path().get_base_dir().path_join(relative_path)
		if FileAccess.file_exists(executable_path):
			return executable_path

	var resource_path = "res://".path_join(relative_path)
	if FileAccess.file_exists(resource_path):
		return resource_path

	return ""


static func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.count(".") == 3 and not ip.begins_with("127."):
			if (
				ip.begins_with("10.")
				or ip.begins_with("192.168.")
				or (ip.begins_with("172.") and int(ip.split(".")[1]) in range(16, 32))
			):
				return ip
	return "127.0.0.1"


static func _run_text_script(handler: ConsoleHandler, code: String) -> void:
	var script = GDScript.new()
	script.source_code = code
	var error = script.reload()
	if error == OK:
		var instance = script.new()
		instance.call("run")
	else:
		handler.log_error("console", "Failed to compile script!")


#endregion


#region Subclasses
class Argument:
	var argument_name: String
	var value_type: int = TYPE_STRING

	func _init(_name: String = "", _type: int = TYPE_STRING) -> void:
		argument_name = _name
		value_type = _type


class RegisteredCommand:
	var arguments: Array
	var action: Callable
	var description: String
	var hidden: bool

	func _init(
		_args: Array, _action: Callable, _description: String = "", _hidden: bool = false
	) -> void:
		arguments = _args.duplicate()
		action = _action
		description = _description
		hidden = _hidden
#endregion
