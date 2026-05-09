<pre>
  ______     ______   ______     ______     __    __
 /\  ___\   /\__  _\ /\  ___\   /\  == \   /\ "-./  \
 \ \ \__ \  \/_/\ \/ \ \  __\   \ \  __<   \ \ \-./\ \
  \ \_____\    \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \ \_\
   \/_____/     \/_/   \/_____/   \/_/ /_/   \/_/  \/_/
</pre>

# GTERM - Godot Terminal

GTERM is an in-game developer console for Godot. It provides a popup terminal UI, a shared command registry, command history and suggestions, rich-text logging, and a small TCP service for remote command execution.

The current implementation is built around an autoload singleton named `Console`. On startup it registers built-in commands, spawns the console window, and starts the remote service on port `3939`.

## Current Features

- Built-in and custom command registration through `ConsoleCommands.commands.register(...)`
- Multiple commands in one line using `;`
- Quoted string arguments such as `/print "hello world"`
- RichTextLabel log output with types
- Input history with up/down arrow navigation
- Prefix-based command suggestions in the UI
- Remote command execution over TCP on port `3939`

## Setup

Add `addons/gterm/scripts/console.gd` as an AutoLoad singleton named `Console`.

This name matters because the implementation calls `Console.get_version()` and `Console.get_banner()` from other scripts.

Once the autoload is active, GTERM will:

- register the built-in commands
- instantiate the controller
- start the remote service on port `3939`

## Using The Console

Press `F12` to open the console window.

## Command Syntax

Commands are tokenized by spaces, with quoted strings preserved:

```text
/print "hello world"
```

You can chain commands with semicolons:

```text
/print "one"; /print "two"
```

Argument handling is strict:

- commands with declared arguments require the exact number of arguments
- `TYPE_INT` and `TYPE_FLOAT` values must parse cleanly
- `TYPE_BOOL` treats `true`, `1`, and `yes` as `true`; any other value becomes `false`

## Registering Custom Commands

Register commands through the shared registry:

```gdscript
func _ready() -> void:
	ConsoleCommands.commands.register(
		"/sleep",
		{"time": TYPE_FLOAT},
		cmd_sleep,
		"Sleeps for a given time"
	)


func cmd_sleep(handler: ConsoleHandler, args: Dictionary) -> void:
	await handler.get_tree().create_timer(args["time"]).timeout
	handler.log_info("game", "Finished sleeping")
```

Action signatures supported by the current parser:

- commands with arguments: `func my_command(handler: ConsoleHandler, args: Dictionary) -> void`
- commands without arguments: `func my_command(handler: ConsoleHandler) -> void`

Use the optional `hidden` flag when registering a command if it should be omitted from `/help` and the suggestion list.

## Built-in Commands

These commands are registered by `ConsoleCommands.register_all()`, plus one UI command added by the controller:

- `/sleep [time: float]`
  Waits for the given number of seconds.
- `/exec [file_name: string]`
  Reads a text file and executes its contents as console commands.
- `/load_mod [file_name: string]`
  Loads a `.pck` resource pack.
- `/load_script [file_name: string]`
  Reads a `.gd` file, compiles it at runtime, and calls its `run(handler)` function.
- `/clear`
  Clears the console log.
- `/pause [pause: bool]`
  Sets `Engine.time_scale` to `0.0` when true, or `1.0` when false.
- `/game-speed [time: float]`
  Sets `Engine.time_scale` directly.
- `/fps-cap [cap: int]`
  Sets `Engine.max_fps`.
- `/vsync [state: bool]`
  Enables or disables VSync for the window.
- `/monitor_info`
  Prints resolution, refresh rate, and DPI for each monitor.
- `/version`
  Prints the current GTERM version.
- `/stats`
  Prints current FPS and window resolution.
- `/network`
  Prints the first detected private IPv4 address, or `127.0.0.1`.
- `/print [text: string]`
  Prints text to the console log.
- `/help`
  Lists all non-hidden registered commands.
- `/center`
  Re-centers the console window on screen.

## File-Based Commands

`/exec` and `/load_script` read from different base paths depending on runtime:

- in the editor: relative to the project `res://` root
- in exported builds: relative to the executable directory

Examples:

```text
/exec scripts/dev_commands.cfg
/load_script scripts/debug_runner.gd
```

For `/load_mod`, pass a path to a `.pck` file that `ProjectSettings.globalize_path(...)` can resolve.

## Remote Access

GTERM starts a TCP server on port `3939`.

You can connect with `nc`:

```text
nc <machine-ip> 3939
```

## Version

The current version is `1.0.1`.
