extends SceneTree

## Compiles the scripts given after `--` the way the game does, with the
## project's autoloads registered, and exits 1 if one of them fails:
##     godot --headless --path . -s tools/check_script.gd -- scenes/player_2d.gd
## `godot --check-only -s file.gd` compiles its file before the autoloads exist
## and so reports "Identifier not found" on any valid script that uses one.


func _initialize() -> void:
	var failed := PackedStringArray()
	var paths := OS.get_cmdline_user_args()
	for path in paths:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if script == null or not script.can_instantiate():
			failed.append(path)
	for path in failed:
		printerr("check_script: %s does not compile" % path)
	if paths.is_empty():
		printerr("check_script: no script given after --")
	quit(1 if paths.is_empty() or not failed.is_empty() else 0)
