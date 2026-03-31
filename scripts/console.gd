extends Node

const BANNER_PATH: String = "%s/../graphics/intro.txt"
static var _welcome_banner: String = ""
var console_controller: ConsoleController = null
var _service: ConsoleService = null


func _enter_tree() -> void:
	ConsoleCommands.register_all()
	_spawn_menu()
	_start_service()
	_welcome_banner = _load_banner()


func _load_banner() -> String:
	var script_folder: String = get_script().resource_path.get_base_dir()
	var intro_anim_path: String = BANNER_PATH % script_folder
	intro_anim_path = ProjectSettings.localize_path(intro_anim_path)
	var ascii_art: String = FileAccess.get_file_as_string(intro_anim_path)
	return ascii_art % get_version()


func get_version() -> String:
	return "1.0.0"


func get_banner() -> String:
	return _welcome_banner


#region Private


func _spawn_menu() -> void:
	var script_file = get_script().resource_path
	var current_folder = script_file.get_base_dir()
	var parent_folder = current_folder.get_base_dir()
	var packed_scene = load(parent_folder + "/%s/%s" % ["scenes", "console.tscn"])
	var instance = packed_scene.instantiate()
	add_child(instance)
	console_controller = instance


func _start_service() -> void:
	if _service == null:
		_service = ConsoleService.new()
		add_child(_service)
	_service.start_service()

#endregion
