<pre>
  ______     ______   ______     ______     __    __
 /\  ___\   /\__  _\ /\  ___\   /\  == \   /\ "-./  \
 \ \ \__ \  \/_/\ \/ \ \  __\   \ \  __<   \ \ \-./\ \
  \ \_____\    \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \ \_\
   \/_____/     \/_/   \/_____/   \/_/ /_/   \/_/  \/_/
</pre>

# GTERM

GTERM is a small in-game terminal for Godot projects. It gives you a popup console, command history, suggestions, rich-text logs, custom commands, and a TCP service for sending commands from outside the game.

It is meant for development builds: quick testing, live tuning, small debug scripts, and remote poking when the game is running somewhere else.

## Setup

Add `addons/gterm/scripts/console.gd` as an AutoLoad singleton named `Console`.

That is all the addon needs to boot. When the game starts, GTERM registers its built-in commands, creates the console window, and starts the remote service on the configured port.

The default config lives at `addons/gterm/configs/settings.cfg`:

```ini
[console]
remote_port=3939
version="1.0.1"
```

## Opening And Closing

Press `F12` to open the console. Press `F12` again, click the close button, or close the window to hide it.

Inside the console, type a command and press Enter:

```text
/print "hello world"
```

Use `/help` in the console to see the commands available in the current build.

## Syntax

Commands start with `/` and arguments are separated by spaces.

Quoted strings stay together:

```text
/print "hello world"
```

You can run more than one command in a single line with semicolons:

```text
/print "one"; /print "two"
```

Arguments are strict. A command that declares two arguments needs two arguments, and typed values like `TYPE_INT` or `TYPE_FLOAT` must parse cleanly.

For booleans, `true`, `1`, and `yes` are treated as true. Anything else is false.

## Registering Commands

Register commands through `Console.register_command(...)`:

```gdscript
func _ready() -> void:
	Console.register_command({
		"name": "/heal",
		"description": "Restores player health",
		"arguments": {"amount": TYPE_INT},
		"action": _cmd_heal,
	})


func _cmd_heal(handler: ConsoleHandler, args: Dictionary) -> void:
	var amount: int = args["amount"]
	player.heal(amount)
	handler.log_info("game", "Healed player by %d" % amount)
```

Command actions can use either of these signatures:

```gdscript
func my_command(handler: ConsoleHandler) -> void:
	pass


func my_command(handler: ConsoleHandler, args: Dictionary) -> void:
	pass
```

`ConsoleHandler` gives the command a way to write back to the console with helpers like `log_info`, `log_warn`, `log_error`, and `log_clear`.

## Files And Scripts

`/exec` runs console commands from a text file. `/load-script` compiles a `.gd` file at runtime and calls its `run()` function.

```text
/exec scripts/dev_commands.cfg
/load-script scripts/debug_runner.gd
```

Relative paths are resolved from:

1. The executable directory, in exported builds
2. The project `res://` root

That means a sidecar file next to the executable can override a packed file with the same relative path.

## Remote Service

GTERM starts a TCP service on port `3939` by default. You can connect with a simple TCP client:

```text
nc <machine-ip> 3939
```

Once connected, type the same commands you would type in the in-game console. Use `/help` to list commands, or `exit` / `quit` to disconnect.

Change the port in `addons/gterm/configs/settings.cfg`:

```ini
[console]
remote_port=3939
```

## Built-In Commands

The main README keeps things short. For the complete command reference, see [BUILT_IN_COMMANDS.md](BUILT_IN_COMMANDS.md).
