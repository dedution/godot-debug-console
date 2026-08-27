extends Node

signal on_register_command

const SCENE_PATH: String = "%s/scenes/console.tscn"
const BANNER_PATH: String = "%s/graphics/intro.txt"
const CONFIG_PATH: String = "%s/configs/settings.cfg"

var console_controller: ConsoleController = null
var _parent_folder: String
var _startup_banner: String = ""
var _service: ConsoleService = null
var _web_client: ConsoleWebClient = null
var _console_config: ConfigFile = ConfigFile.new()

## Communication with game systems should be done with a SignalDispatcher for more versatility,
## never direct calls.
## This system should also be stripped from build release versions


#region Setup
func _enter_tree() -> void:
	# Find the addon parent folder and cache it
	var script_file = get_script().resource_path
	var current_folder = script_file.get_base_dir()
	_parent_folder = current_folder.get_base_dir()

	_load_configs()
	_load_banner()
	_start_service()
	_register_commands()
	_spawn_menu()
	_start_web_interface()


func _load_configs() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH % _parent_folder)

	if err == OK:
		_console_config = config
	else:
		push_error("GTerm failed to load config!")


## Loads and sets up the console controller
func _spawn_menu() -> void:
	var packed_scene = load(SCENE_PATH % _parent_folder)
	console_controller = packed_scene.instantiate()
	console_controller.console_manager = self
	add_child(console_controller)


func _register_commands() -> void:
	Commands.register("/version", {}, _cmd_version, "Prints the console version")
	Commands.register_all()


func _cmd_version(handler: ConsoleHandler) -> void:
	handler.log_info("console", "Console version: %s" % get_version())


## New CLI interface using the web browser for better access
func _start_web_interface() -> void:
	if _web_client != null:
		push_error("GTerm web interface already running.")
		return

	var use_web_interface: bool = _console_config.get_value("console", "use_web_interface", true)
	if not use_web_interface:
		return

	_web_client = ConsoleWebClient.new(self)
	_web_client.start_service(
		_console_config.get_value("console", "web_port", 6969),
		_console_config.get_value("console", "service_port", 3939)
	)


func _start_service() -> void:
	if _service != null:
		push_error("GTerm websocket service already running.")
		return

	_service = ConsoleService.new(self)
	_service.start_service(_console_config.get_value("console", "service_port", 3939))


func _load_banner() -> void:
	var ascii_art: String = FileAccess.get_file_as_string(BANNER_PATH % _parent_folder)
	_startup_banner = ascii_art % get_version()


#endregion


#region Public
func get_version() -> String:
	return _console_config.get_value("console", "version", "1.0.0")


func get_transparency() -> float:
	return _console_config.get_value("visual", "transparency_amount", 1.0)


func get_editor_scale_multiplier() -> float:
	return _console_config.get_value("visual", "editor_scale_multiplier", 1.0)


func get_banner() -> String:
	return _startup_banner


## Registers the console command.
##
## Expected fields in 'parameters':
## - name: String
## - description: String
## - arguments: Dictionary with formated args. Ex: {"arg1": TYPE_INT, "arg2": TYPE_BOOL}
## - action: Callable
func register_command(parameters: Dictionary) -> void:
	var cmd_name: String = parameters.get("name", "")
	var cmd_arguments: Dictionary = parameters.get("arguments", "")
	var cmd_action: Callable = parameters.get("action", "")
	var cmd_description: String = parameters.get("description", "")
	Commands.register(cmd_name, cmd_arguments, cmd_action, cmd_description)

#endregion
