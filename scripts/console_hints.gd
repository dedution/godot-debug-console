class_name ConsoleHints
extends Node

const MAX_DISPLAYED_HINTS := 5

@export var button_hint_template: Button
@export var input_writer: ConsoleWriter
var buttons: Array[Button]


func _ready() -> void:
	build_buttons()
	input_writer.text_changed.connect(process_suggestions)
	input_writer.text_autocomplete.connect(_on_input_autocomplete)


func build_buttons() -> void:
	button_hint_template.visible = false

	for i in MAX_DISPLAYED_HINTS:
		var new_hint_button: Button = button_hint_template.duplicate(true)
		button_hint_template.get_parent().add_child(new_hint_button)
		button_hint_template.name = "Hint Button %d" % i
		new_hint_button.pressed.connect(_on_hint_button_pressed.bind(new_hint_button))
		buttons.push_back(new_hint_button)


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

	# Review this sorting...
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
	_complete_command(button.text)


func _on_input_autocomplete() -> void:
	if !buttons[0].text.is_empty():
		_complete_command(buttons[0].text)


func _complete_command(command: String):
	var commands: PackedStringArray = input_writer.text.split(";", false)
	commands[commands.size() - 1] = command

	var commands_final: String = ""
	for cmd_id in range(0, commands.size()):
		commands_final += commands[cmd_id]
		if cmd_id != commands.size() - 1:
			commands_final += ";"

	input_writer.force_command(commands_final)


func _sort_command_matches(a: String, b: String) -> bool:
	if a.length() == b.length():
		return a.naturalnocasecmp_to(b) < 0
	return a.length() < b.length()
