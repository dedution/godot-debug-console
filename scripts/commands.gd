class_name Commands
extends RefCounted

var _registered_commands: Dictionary = {}


#region Public
func register(
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


func get_commands() -> Dictionary:
	return _registered_commands


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
