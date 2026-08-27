class_name ConsoleController
extends ConsoleHandler

const LOG_INFO_COLOR: String = "c3d8e9"
const LOG_WARN_COLOR: String = "f1c458"
const LOG_ERROR_COLOR: String = "ff8a99"
const OPEN_ANIMATION_TIME: float = 0.26
const OPEN_ANIMATION_OFFSET_Y: float = 18.0
const OPEN_ANIMATION_START_SCALE: float = 0.96
const OPEN_ANIMATION_OVERSHOOT_SCALE: float = 1.01
const BASE_WINDOW_SIZE: Vector2i = Vector2i(620, 750)
const BASE_WINDOW_MAX_SIZE: Vector2i = Vector2i(1100, 1500)
const EDITOR_SCALE_REFERENCE_SIZE: Vector2 = Vector2(1020, 1800)
const EDITOR_SCALE_MAX: float = 1.9
const EDITOR_WIDTH_SCALE_BOOST: float = 1.18
const BASE_TITLE_HEIGHT: float = 34.0
const BASE_LOG_BOTTOM_MARGIN: float = 126.0
const BASE_INPUT_HEIGHT: float = 50.0
const BASE_TITLE_FONT_SIZE: int = 14
const BASE_CLOSE_FONT_SIZE: int = 15
const BASE_LOG_FONT_SIZE: int = 18
const BASE_INPUT_FONT_SIZE: int = 18
const BASE_HINT_FONT_SIZE: int = 16

var console_manager: Node

var _open_tween: Tween = null
var _drag_active: bool = false
var _drag_start_mouse_position: Vector2i = Vector2i.ZERO
var _drag_start_window_position: Vector2i = Vector2i.ZERO

## References to other console components
@onready var _window: Window = $Window
@onready var _background: ColorRect = $Window/Container/Inner/Background
@onready var _vbox: VBoxContainer = $Window/Container/Inner/VBoxContainer
@onready var _input_container: Control = $Window/Container/Inner/VBoxContainer/Input
@onready var _command_indicator: TextureRect = _input_container.get_node("CommandIndicator")
@onready var _writer: ConsoleWriter = $Window/Container/Inner/VBoxContainer/Input/CommandEdit
@onready var _logger: ConsoleLogger = $Window/Container/Inner/VBoxContainer/Logger
@onready var _logs: RichTextLabel = $Window/Container/Inner/VBoxContainer/Logger/Logs

## Transparent elements
@onready var _hints_panel: PanelContainer = $Window/Container/Inner/Hints
@onready var _suggestion_container: VBoxContainer = _hints_panel.get_node("SuggestionContainer")

## Borderless window and animation
@onready var _content: Control = $Window/Container/Inner
@onready var _title_bar: Control = $Window/Container/Inner/TitleBar
@onready var _title_label: Label = $Window/Container/Inner/TitleBar/TitleLabel
@onready var _close_button: Button = $Window/Container/Inner/TitleBar/CloseButton


func _ready() -> void:
	_writer.console_controller = self
	_logger.console_manager = console_manager
	_window.close_requested.connect(close_menu)
	_writer.text_submit.connect(_on_input_submitted)
	_close_button.pressed.connect(close_menu)
	_title_bar.gui_input.connect(_on_title_bar_gui_input)
	set_process(true)
	_apply_editor_scaling()
	close_menu()
	_process_transparent_elements()

	# Register command to center window
	Commands.register("/center", {}, _center_window, "Centers the console window")


func _process_transparent_elements() -> void:
	if !console_manager:
		return

	# For color rect
	_background.color.a = console_manager.get_transparency()

	# For theme overrides like the hints panel
	var style = _hints_panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color.a = console_manager.get_transparency()


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


func _apply_editor_scaling() -> void:
	if not OS.has_feature("editor"):
		return

	var screen_size = get_viewport().get_visible_rect().size
	var editor_scale = min(
		screen_size.x / EDITOR_SCALE_REFERENCE_SIZE.x, screen_size.y / EDITOR_SCALE_REFERENCE_SIZE.y
	)

	editor_scale = clampf(editor_scale, 1.0, EDITOR_SCALE_MAX)
	editor_scale *= _get_editor_scale_multiplier()

	var window_scale = Vector2(editor_scale * EDITOR_WIDTH_SCALE_BOOST, editor_scale)
	_window.size = _scaled_window_size(BASE_WINDOW_SIZE, window_scale)
	_window.min_size = _window.size
	_window.max_size = _scaled_window_size(BASE_WINDOW_MAX_SIZE, window_scale)
	_apply_editor_control_scaling(editor_scale)


func _apply_editor_control_scaling(editor_scale: float) -> void:
	_background.offset_top = BASE_TITLE_HEIGHT * editor_scale
	_background.offset_bottom = -BASE_LOG_BOTTOM_MARGIN * editor_scale

	_title_bar.custom_minimum_size = Vector2(0.0, BASE_TITLE_HEIGHT * editor_scale)
	_title_bar.offset_bottom = BASE_TITLE_HEIGHT * editor_scale

	_title_label.offset_left = 12.0 * editor_scale
	_title_label.offset_top = 8.0 * editor_scale
	_title_label.offset_right = 420.0 * editor_scale
	_title_label.offset_bottom = 26.0 * editor_scale
	_title_label.add_theme_font_size_override(
		"font_size", roundi(BASE_TITLE_FONT_SIZE * editor_scale)
	)

	_close_button.custom_minimum_size = Vector2(28.0, 24.0) * editor_scale
	_close_button.offset_left = -34.0 * editor_scale
	_close_button.offset_top = 5.0 * editor_scale
	_close_button.offset_right = -6.0 * editor_scale
	_close_button.offset_bottom = 29.0 * editor_scale
	_close_button.add_theme_font_size_override(
		"font_size", roundi(BASE_CLOSE_FONT_SIZE * editor_scale)
	)

	_vbox.offset_top = BASE_TITLE_HEIGHT * editor_scale
	_input_container.custom_minimum_size = Vector2(0.0, BASE_INPUT_HEIGHT * editor_scale)

	_command_indicator.offset_left = 25.125 * editor_scale
	_command_indicator.offset_top = -8.665001 * editor_scale
	_command_indicator.offset_right = 45.125 * editor_scale
	_command_indicator.offset_bottom = 11.335049 * editor_scale
	_command_indicator.pivot_offset = Vector2(10.0, 10.0) * editor_scale

	_writer.offset_left = 63.0 * editor_scale
	_writer.add_theme_font_size_override("font_size", roundi(BASE_INPUT_FONT_SIZE * editor_scale))

	_logs.add_theme_font_size_override(
		"normal_font_size", roundi(BASE_LOG_FONT_SIZE * editor_scale)
	)

	for child in _suggestion_container.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0.0, 38.51 * editor_scale)
			child.add_theme_font_size_override(
				"font_size", roundi(BASE_HINT_FONT_SIZE * editor_scale)
			)


func _scaled_window_size(size: Vector2i, scale: Vector2) -> Vector2i:
	return Vector2i(roundi(size.x * scale.x), roundi(size.y * scale.y))


func _get_editor_scale_multiplier() -> float:
	if console_manager and console_manager.has_method("get_editor_scale_multiplier"):
		return console_manager.get_editor_scale_multiplier()

	return 1.0


func get_version() -> String:
	if console_manager:
		return console_manager.get_version()

	return ""


func open_menu() -> void:
	_apply_editor_scaling()
	_sync_window_title()
	_window.visible = true
	_center_window(null)
	_play_open_animation()
	_window.grab_focus()
	_writer.grab_focus()
	_logger.open_console()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_menu() -> void:
	_window.visible = false
	_window.gui_release_focus()
	_reset_content_state()
	_drag_active = false


func _input(event) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		if _window.visible:
			close_menu()
		else:
			open_menu()


func _process(_delta: float) -> void:
	if _drag_active:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drag_active = false
		else:
			_update_window_drag()


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


func _play_open_animation() -> void:
	_reset_content_state()
	_content.pivot_offset = _content.size * 0.5
	_content.modulate = Color(1, 1, 1, 0)
	_content.position = Vector2(0, OPEN_ANIMATION_OFFSET_Y)
	_content.scale = Vector2(OPEN_ANIMATION_START_SCALE, OPEN_ANIMATION_START_SCALE)

	_open_tween = create_tween()
	_open_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_open_tween.parallel().tween_property(_content, "modulate", Color.WHITE, OPEN_ANIMATION_TIME)
	_open_tween.parallel().tween_property(_content, "position", Vector2.ZERO, OPEN_ANIMATION_TIME)
	_open_tween.parallel().tween_property(
		_content,
		"scale",
		Vector2(OPEN_ANIMATION_OVERSHOOT_SCALE, OPEN_ANIMATION_OVERSHOOT_SCALE),
		OPEN_ANIMATION_TIME * 0.75
	)
	_open_tween.tween_property(_content, "scale", Vector2.ONE, OPEN_ANIMATION_TIME * 0.25)


func _reset_content_state() -> void:
	if _open_tween != null:
		_open_tween.kill()
		_open_tween = null

	_content.modulate = Color.WHITE
	_content.position = Vector2.ZERO
	_content.scale = Vector2.ONE


func _sync_window_title() -> void:
	var title := "GTerm - v%s" % get_version()
	_window.title = title
	_title_label.text = title


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_drag_active = true
		_drag_start_mouse_position = DisplayServer.mouse_get_position()
		_drag_start_window_position = _window.position
		_title_bar.accept_event()


func _update_window_drag() -> void:
	var mouse_delta: Vector2i = DisplayServer.mouse_get_position() - _drag_start_mouse_position
	_window.position = _drag_start_window_position + mouse_delta
