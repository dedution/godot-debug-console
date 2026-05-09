class_name ConsoleHints
extends Node

@export var buttons: Array[Button]
@onready var _input_writer: ConsoleWriter = $"../Input/CommandEdit"


func _ready() -> void:
	_input_writer.text_changed.connect(process_suggestions)
	_input_writer.text_autocomplete.connect(_on_input_autocomplete)
	for btn in buttons:
		btn.pressed.connect(_on_hint_button_pressed.bind(btn))
		btn.visible = false


func process_suggestions(command: String) -> void:
	if command == "":
		_clear_buttons()
		return

	var commands: Dictionary = ConsoleCommands.commands.get_commands()
	var matches: Array[String] = []

	var command_parts := command.split(";", false)
	var last_command := command_parts[command_parts.size() - 1].strip_edges()

	if last_command == "":
		_clear_buttons()
		return

	var parts := last_command.split(" ", false)
	if parts.size() == 0:
		_clear_buttons()
		return

	var user_prefix := parts[0]
	if user_prefix.begins_with("/"):
		user_prefix = user_prefix.substr(1, user_prefix.length() - 1)
	user_prefix = user_prefix.to_lower()

	# Find matches
	for cmd in commands.keys():
		if commands[cmd].hidden:
			continue

		var cmd_name := str(cmd)
		if cmd_name.begins_with("/"):
			cmd_name = cmd_name.substr(1, cmd_name.length() - 1)
		cmd_name = cmd_name.to_lower()

		if cmd_name.begins_with(user_prefix):
			matches.append(str(cmd))

	# Hide hints if the user already typed a command with arguments
	if matches.has(parts[0]):
		_clear_buttons()
		return

	if matches.size() > 0:
		matches.sort_custom(_sort_command_matches)
		_set_hint_buttons(matches)
	else:
		_clear_buttons()


func _set_hint_buttons(hints_data: Array) -> void:
	for i in range(buttons.size()):
		if i < hints_data.size():
			buttons[i].text = hints_data[i]
			buttons[i].visible = true
		else:
			buttons[i].visible = false


func _clear_buttons() -> void:
	for btn in buttons:
		btn.visible = false


func _on_hint_button_pressed(button: Button) -> void:
	var commands: PackedStringArray = _input_writer.text.split(";", false)  # PackedStringArray
	commands[commands.size() - 1] = button.text

	var commands_final: String = ""
	for cmd_id in range(0, commands.size()):
		commands_final += commands[cmd_id]
		if cmd_id != commands.size() - 1:
			commands_final += ";"

	_input_writer.force_command(commands_final)


func _sort_command_matches(a, b) -> int:
	if a.length() < b.length():
		return -1
	return 1


func _on_input_autocomplete() -> void:
	if !buttons[0].text.is_empty():
		_input_writer.force_command(buttons[0].text)
