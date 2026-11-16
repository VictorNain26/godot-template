extends Node
## Started by `-- --selftest` (the Prefs autoload adds it). An exported build
## has no tests in it, so this is how a build proves it holds what the game
## needs: the translations, the fonts and their licences, and every scene of
## res://scenes loading and staying on stage. A game adds its own checks with
## a `static func self_test() -> Array[String]` in its kit config, returning
## what failed; it may await frames (building each level takes a few). Prints
## SELFTEST OK or SELFTEST FAILED and sets the exit code.
## Part of the kit (addons/kit).

const FRAMES := 40
const SCENES := "res://scenes"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var failures: Array[String] = []
	await get_tree().process_frame
	if TranslationServer.get_loaded_locales().has("en"):
		TranslationServer.set_locale("en")
		if Loc.t("Reprendre") != "Resume":
			failures.append("the English translation is not in the build")
		TranslationServer.set_locale(Prefs.settings.locale)
	failures += fonts()
	for scene in scenes():
		get_tree().change_scene_to_file(scene)
		for frame in FRAMES:
			await get_tree().process_frame
		if not on_stage(get_tree().current_scene, scene):
			failures.append("%s did not load" % scene)
	var path := str(ProjectSettings.get_setting(Prefs.CONFIG_SETTING, Prefs.DEFAULT_CONFIG))
	var config := load(path) as GDScript if ResourceLoader.exists(path) else null
	if config != null and config.has_method(&"self_test"):
		var more: Variant = await config.call(&"self_test")
		if more is Array:
			for failure: Variant in more as Array:
				failures.append(str(failure))
	if failures.is_empty():
		print("SELFTEST OK")
	else:
		print("SELFTEST FAILED: " + "; ".join(failures))
	get_tree().quit(0 if failures.is_empty() else 1)


## The two typefaces and their licences are in the build, and a text that
## names no font gets the reading face, not the engine's own.
static func fonts() -> Array[String]:
	var out: Array[String] = []
	for path: String in [UiStyle.DISPLAY_PATH, UiStyle.BODY_PATH]:
		if not ResourceLoader.exists(path) or not load(path) is FontFile:
			out.append("%s is not in the build" % path)
	for path: String in UiStyle.LICENCES:
		if not FileAccess.file_exists(path):
			out.append("%s is not in the build" % path)
	if ThemeDB.fallback_font.get_font_name() != UiStyle.body().get_font_name():
		out.append("the default font is not the reading face")
	return out


## Every scene under res://scenes, as an exported build lists them (a scene
## is converted there and listed with a .remap beside it).
static func scenes() -> Array[String]:
	var found := {}
	for file in DirAccess.get_files_at(SCENES):
		var name := file.trim_suffix(".remap")
		if name.get_extension() in ["tscn", "scn"]:
			found[SCENES.path_join(name)] = true
	var out: Array[String] = []
	for scene: String in found:
		out.append(scene)
	out.sort()
	return out


## True once `scene_path` is the scene on stage. A scene that fails to load
## leaves the previous one where it was: "there is a scene" proves nothing.
static func on_stage(current: Node, scene_path: String) -> bool:
	return current != null and current.scene_file_path == scene_path
