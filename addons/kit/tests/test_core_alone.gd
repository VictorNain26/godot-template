extends GdUnitTestSuite

## The kit works without its menus: a game may delete addons/kit_ui and write
## its own. No script of the kit names a class or a file of the menus; what
## they add (skin, export checks, clicks) reaches the kit through the game's
## kit config. tools/kit_core_check.sh proves it on a project that has no
## menus at all. Part of the kit (addons/kit).

const CORE := "res://addons/kit"
const MENUS := "res://addons/kit_ui"


func _scripts(dir: String, out: Array[String]) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(sub), out)


## The class names the menus declare, read from their scripts.
func _menu_classes() -> Array[String]:
	var files: Array[String] = []
	_scripts(MENUS, files)
	var declared := RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	var out: Array[String] = []
	for file in files:
		var hit := declared.search(FileAccess.get_file_as_string(file))
		if hit != null:
			out.append(hit.get_string(1))
	return out


## The script without its comment lines: a comment may point to the menus.
func _code(script: String) -> String:
	var kept: Array[String] = []
	for line in script.split("\n"):
		if not line.strip_edges().begins_with("#"):
			kept.append(line)
	return "\n".join(kept)


func test_the_menus_declare_classes_to_look_for() -> void:
	if not DirAccess.dir_exists_absolute(MENUS):
		return
	assert_array(_menu_classes()).contains(["UiStyle", "OptionsMenu", "PauseMenu"])


func test_no_script_of_the_kit_names_the_menus() -> void:
	if not DirAccess.dir_exists_absolute(MENUS):
		return
	var files: Array[String] = []
	_scripts(CORE, files)
	var named: Array[String] = []
	# This test names them to look for them.
	var me: Script = get_script()
	files.erase(me.resource_path)
	for file in files:
		var code := _code(FileAccess.get_file_as_string(file))
		if code.contains("addons/kit_ui"):
			named.append("%s: addons/kit_ui" % file)
		for menu_class in _menu_classes():
			if RegEx.create_from_string("\\b%s\\b" % menu_class).search(code) != null:
				named.append("%s: %s" % [file, menu_class])
	assert_array(named).override_failure_message("the kit names its menus: %s" % [named]).is_empty()


func test_the_kit_and_every_kit_addon_get_the_warnings() -> void:
	# res://addons is left out of the warnings by default (third-party code):
	# each kit folder must be put back in, or its errors go unseen.
	var rules: Dictionary = ProjectSettings.get_setting(
		"debug/gdscript/warnings/directory_rules", {}
	)
	var dirs: Array[String] = [CORE]
	for sub in DirAccess.get_directories_at("res://addons"):
		if sub.begins_with("kit_"):
			dirs.append("res://addons".path_join(sub))
	for dir in dirs:
		var level: int = rules.get(dir, 0)
		var told := (
			"%s is not in debug/gdscript/warnings/directory_rules: its warnings go unseen" % dir
		)
		assert_int(level).override_failure_message(told).is_equal(1)
