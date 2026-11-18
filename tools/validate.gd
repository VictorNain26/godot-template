extends SceneTree
## Loads every script, scene and shader of the project and fails on the first
## one that does not compile: `mise run validate`. Unlike
## `godot --check-only --script`, this runs with the autoloads registered, so
## a script that uses one is checked correctly. A test script that does not
## parse would otherwise be skipped by the test runner without a failure.

const ROOTS: Array[String] = [
	"res://src",
	"res://scenes",
	"res://tests",
	"res://tools",
	"res://addons/kit",
	"res://addons/kit_ui",
	"res://kit_config.gd"
]
const EXTENSIONS: Array[String] = ["gd", "tscn", "gdshader"]


func _initialize() -> void:
	var failed: Array[String] = []
	var count := 0
	var me: Script = get_script()
	for root_dir in ROOTS:
		for path in _files(root_dir):
			# Loading the running script again, uncached, hangs the engine.
			if path == me.resource_path:
				continue
			count += 1
			var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if res == null:
				failed.append(path)
			elif res is GDScript and not (res as GDScript).can_instantiate():
				failed.append(path)
	if failed.is_empty():
		print("validate: %d files OK" % count)
		quit(0)
	else:
		for path in failed:
			printerr("validate: FAILED to load " + path)
		quit(1)


func _files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	if dir_path.get_extension() in EXTENSIONS:
		return [dir_path]
	var dir := DirAccess.open(dir_path)
	# A folder with a .gdignore is not part of the project (Godot skips it).
	if dir == null or dir.file_exists(".gdignore"):
		return out
	for sub in dir.get_directories():
		out.append_array(_files(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.get_extension() in EXTENSIONS:
			out.append(dir_path.path_join(file))
	return out
