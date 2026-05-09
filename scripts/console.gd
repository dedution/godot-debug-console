extends Node

const BANNER_PATH: String = "%s/../graphics/intro.txt"
var console_controller: ConsoleController = null
var _startup_banner: String = ""
var _service: ConsoleService = null

## Communication with game systems should be done with a SignalDispatcher for more versatility, never direct calls.
## This system should also be stripped from build release versions


#region Setup
func _enter_tree() -> void:
	_startup_banner = _load_banner()
	_register_commands()
	_spawn_menu()
	_start_service()


#endregion


#region Public
func get_version() -> String:
	return "1.0.0"


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
	ConsoleCommands.commands.register(cmd_name, cmd_arguments, cmd_action, cmd_description)


#endregion

#region Private


## Loads and sets up the console controller
func _spawn_menu() -> void:
	var script_file = get_script().resource_path
	var current_folder = script_file.get_base_dir()
	var parent_folder = current_folder.get_base_dir()
	var packed_scene = load(parent_folder + "/%s/%s" % ["scenes", "console.tscn"])
	var instance = packed_scene.instantiate()
	add_child(instance)
	console_controller = instance
	console_controller.console_manager = self


func _register_commands() -> void:
	ConsoleCommands.commands.register("/version", {}, _cmd_version, "Prints the console version")
	ConsoleCommands.register_all()


func _cmd_version(handler: ConsoleHandler) -> void:
	handler.log_info("console", "Console version: %s" % get_version())


func _start_service() -> void:
	if _service == null:
		_service = ConsoleService.new(self)
		add_child(_service)
	_service.start_service()


func _load_banner() -> String:
	var script_folder: String = get_script().resource_path.get_base_dir()
	var intro_anim_path: String = BANNER_PATH % script_folder
	intro_anim_path = ProjectSettings.localize_path(intro_anim_path)
	var ascii_art: String = FileAccess.get_file_as_string(intro_anim_path)
	return ascii_art % get_version()

#endregion
