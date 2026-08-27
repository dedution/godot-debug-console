class_name ConsoleLogger
extends Control

const MAX_LOGS: int = 300
var console_manager: Console
var _logs: Array[String] = []

@onready var _command_logger: RichTextLabel = $Logs


func open_console() -> void:
	_print_intro()


func _print_intro() -> void:
	# Fallback
	if !console_manager or !console_manager.has_method("get_banner"):
		_logs.clear()
		_logs.append(rainbow_text("Welcome to GTERM."))
		_update_display()
		return

	# Get the ascii art to animate and clear current logs
	var ascii_art = console_manager.get_banner()
	clear_log()

	# Animate the ascii art
	var current_text = ""
	var frame_count: int = 0
	var chars_per_frame: int = 10
	for char in ascii_art:
		current_text += char
		frame_count += 1
		if frame_count >= chars_per_frame:
			frame_count = 0
			_logs.clear()
			_logs.append(rainbow_text(current_text))
			_update_display()
			await get_tree().process_frame

	# Remaining chars
	if frame_count > 0:
		_logs.clear()
		_logs.append(rainbow_text(current_text))
		_update_display()
		await get_tree().process_frame

	# Line break
	_logs.append("")
	_update_display()


func rainbow_text(text: String) -> String:
	var result: String = ""
	var hue: float = 0.0
	var hue_step: float = 1.0 / max(text.length(), 1)  # full rainbow over the whole length

	for c in text:
		var col := Color.from_hsv(hue, 1.0, 1.0)
		result += "[color=%s]%s[/color]" % [col.to_html(false), c]
		hue += hue_step

	return result


func add_log(log_tag: String, output: String, color: String = "white") -> void:
	var line: String = "[%s] %s" % [log_tag.to_upper(), output]

	if color == "rainbow":
		line = "[%s] %s" % [log_tag.to_upper(), rainbow_text(output)]
	else:
		line = "[color=%s]%s[/color]" % [color, line]

	_logs.append(line)
	if _logs.size() > MAX_LOGS:
		_logs.pop_front()

	_update_display()


func clear_log() -> void:
	_logs.clear()
	_update_display()


func _update_display() -> void:
	var bbcode_text: String = ""
	for log_line in _logs:
		bbcode_text += log_line + "\n"

	_command_logger.parse_bbcode(bbcode_text)
	_command_logger.scroll_to_line(_command_logger.get_line_count() - 1)
