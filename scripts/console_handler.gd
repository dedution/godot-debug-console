class_name ConsoleHandler
extends Node


func run(handler: ConsoleHandler, command_full: String) -> void:
	var command_list := _split_commands(command_full)
	for cmd in command_list:
		var tokens = _tokenize_command(cmd)
		await _process_command(handler, tokens)


#region Logging
func log_rainbow(_log_tag: String, _output: String) -> void:
	pass


func log_info(_log_tag: String, _output: String) -> void:
	pass


func log_warn(_log_tag: String, _output: String) -> void:
	pass


func log_error(_log_tag: String, _output: String) -> void:
	pass


func log_clear() -> void:
	pass


func _split_commands(command_full: String) -> Array[String]:
	var result: Array[String] = []
	var current: String = ""
	var in_quotes: bool = false

	for c in command_full:
		if c == '"':
			in_quotes = not in_quotes
		elif c == ";" and not in_quotes:
			if current.strip_edges() != "":
				result.append(current.strip_edges())
			current = ""
			continue
		current += c

	if current.strip_edges() != "":
		result.append(current.strip_edges())

	return result


func _process_command(handler: ConsoleHandler, tokens: Array) -> void:
	var registered_commands: Dictionary = Commands.get_commands()
	if tokens.is_empty() or not registered_commands.has(tokens[0]):
		handler.log_error("console", "Failed to execute command [i]%s[/i]" % tokens[0])
		return

	var cmd: Commands.RegisteredCommand = registered_commands[tokens[0]]

	if cmd.arguments.size() > 0 and cmd.arguments.size() != tokens.size() - 1:
		handler.log_error("console", "Arguments for command [i]%s[/i] don't match" % tokens[0])
		handler.log_info("console", "Expected:")
		for argument in cmd.arguments:
			handler.log_info(
				"console",
				(
					"	[i]%s[/i] (%s)"
					% [argument.argument_name, _type_to_string(argument.value_type)]
				)
			)
		return

	var parsed_args: Dictionary = {}

	for i in range(cmd.arguments.size()):
		var arg_def: Commands.Argument = cmd.arguments[i]
		var raw_value: String = tokens[i + 1]
		var value = _parse_argument(raw_value, arg_def.value_type)

		if value == null:
			handler.log_error(
				"console",
				(
					"Argument '%s' has invalid type. Expected %s"
					% [arg_def.argument_name, _type_to_string(arg_def.value_type)]
				)
			)
			return

		parsed_args[arg_def.argument_name] = value

	# Simple commands can have simpler callable parameters
	if cmd.arguments.size() > 0:
		await cmd.action.call(handler, parsed_args)
	else:
		await cmd.action.call(handler)


func _parse_argument(raw_value: String, type_const: int) -> Variant:
	match type_const:
		TYPE_FLOAT:
			if raw_value.is_valid_float():
				return raw_value.to_float()
		TYPE_INT:
			if raw_value.is_valid_int():
				return int(raw_value)
		TYPE_BOOL:
			var lower = raw_value.to_lower()
			if lower in ["true", "1", "yes"]:
				return true
			return false
		TYPE_STRING:
			return raw_value
	return null


func _type_to_string(type_const: int) -> String:
	match type_const:
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_BOOL:
			return "bool"
		TYPE_STRING:
			return "string"
		_:
			return "variant"


func _tokenize_command(command: String) -> Array[String]:
	var regex = RegEx.new()
	regex.compile('("[^"]+"|\\S+)')
	var matches = regex.search_all(command)
	var tokens: Array[String] = []

	for m in matches:
		var token = m.get_string(0)
		if token.begins_with('"') and token.ends_with('"'):
			token = token.substr(1, token.length() - 2)
		tokens.append(token)

	return tokens

#endregion
