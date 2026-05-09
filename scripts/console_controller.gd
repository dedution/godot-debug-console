class_name ConsoleController
extends ConsoleHandler

const LOG_INFO_COLOR: String = "c3d8e9"
const LOG_WARN_COLOR: String = "f1c458"
const LOG_ERROR_COLOR: String = "ff8a99"

var console_manager: Node
@onready var _window: Window = $Window
@onready var _writer: ConsoleWriter = $Window/Container/VBoxContainer/Input/CommandEdit
@onready var _logger: ConsoleLogger = $Window/Container/VBoxContainer/Logger


func _ready() -> void:
	_writer.console_controller = self
	_logger.console_manager = console_manager
	_window.close_requested.connect(close_menu)
	_writer.text_submit.connect(_on_input_submitted)
	close_menu()

	# Register command to center window
	ConsoleCommands.commands.register("/center", {}, _center_window, "Centers the console window")


func _center_window(_handler: ConsoleHandler) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var win_size = _window.size

	# Detect tall screens (e.g. 1920x3240 or anything >1.3 aspect ratio)
	# Experimental. Test on more screen ratios
	var is_tall = screen_size.y > screen_size.x * 1.3
	if is_tall:
		var x = (screen_size.x - win_size.x) * 0.5
		var y = screen_size.y - win_size.y - 150.0
		_window.position = Vector2(x, y)
	else:
		_window.popup_centered()


func get_version() -> String:
	if console_manager and console_manager.has_method("get_version"):
		return console_manager.get_version()

	return ""


func open_menu() -> void:
	_window.title = "GTerm - v%s" % get_version()
	_window.visible = true
	_center_window(null)
	_window.grab_focus()
	_writer.grab_focus()
	_logger.open_console()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_menu() -> void:
	_window.visible = false
	_window.gui_release_focus()


func _input(event) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		if _window.visible:
			close_menu()
		else:
			open_menu()


func _on_input_submitted(command: String) -> void:
	_writer.release_focus()
	_writer.editable = false

	log_info("console", command)
	await run(self, command)
	_writer.editable = true
	_writer.grab_focus()


#region Logging
func log_rainbow(log_tag: String, output: String) -> void:
	if _logger:
		_logger.add_log(log_tag, output, "rainbow")


func log_info(log_tag: String, output: String) -> void:
	if _logger:
		_logger.add_log(log_tag, output, LOG_INFO_COLOR)


func log_warn(log_tag: String, output: String) -> void:
	if _logger:
		_logger.add_log(log_tag, output, LOG_WARN_COLOR)


func log_error(log_tag: String, output: String) -> void:
	if _logger:
		_logger.add_log(log_tag, output, LOG_ERROR_COLOR)


func log_clear() -> void:
	if _logger:
		_logger.clear_log()

#endregion
