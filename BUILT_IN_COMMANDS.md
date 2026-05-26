# Built-In Commands

These commands are registered by GTERM when the `Console` autoload starts. `/center` is registered by the console window, and `/version` is registered by the main console singleton.

Use `/help` at runtime to see the commands available in the current build.

## Console

### `/help`

Lists all non-hidden registered commands.

```text
/help
```

### `/clear`

Clears the console output.

```text
/clear
```

### `/print [text: string]`

Writes text to the console log.

```text
/print "hello world"
```

### `/version`

Prints the current GTERM version from `addons/gterm/configs/settings.cfg`.

```text
/version
```

### `/center`

Moves the console window back to the center of the screen.

```text
/center
```

## Files And Runtime Scripts

### `/exec [file_name: string]`

Reads a text file and runs its contents as console commands.

```text
/exec scripts/dev_commands.cfg
```

### `/load-script [file_name: string]`

Reads a `.gd` file, compiles it at runtime, creates an instance, and calls `run()` with no arguments.

```text
/load-script scripts/debug_runner.gd
```

Example script:

```gdscript
func run() -> void:
	print("debug script ran")
```

`/exec` and `/load-script` resolve relative paths from:

1. The executable directory, in exported builds
2. The project `res://` root

When both locations contain the same relative file, the executable-side file wins.

### `/load-mod [file_name: string]`

Loads a `.pck` resource pack with `ProjectSettings.load_resource_pack(...)`.

```text
/load-mod mods/example.pck
```

## Game State

### `/pause [pause: bool]`

Sets `Engine.time_scale` to `0.0` when true, or `1.0` when false.

```text
/pause true
/pause false
```

### `/game-speed [time: float]`

Sets `Engine.time_scale` directly.

```text
/game-speed 0.5
/game-speed 1.0
```

### `/sleep [time: float]`

Waits for the given number of seconds before the next awaited command work continues.

```text
/sleep 2.0
```

## Rendering

### `/fps-cap [cap: int]`

Sets `Engine.max_fps`.

```text
/fps-cap 60
```

### `/vsync [state: bool]`

Turns VSync on or off for the current window.

```text
/vsync true
/vsync false
```

### `/monitor-info`

Prints resolution, refresh rate, and DPI for each detected monitor.

```text
/monitor-info
```

### `/stats`

Prints the current FPS and window resolution.

```text
/stats
```

## Network

### `/net-stats`

Prints the first detected private IPv4 address, or `127.0.0.1` if none is found.

```text
/net-stats
```
