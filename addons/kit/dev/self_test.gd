extends Node
## Started by `-- --selftest` (the Prefs autoload adds it). An exported build
## has no tests in it, so this is how a build proves it holds what the game
## needs: the translations, the default font, the licences the kit config
## lists (LICENCES), and every scene of res://scenes loading and staying on
## stage. A game adds its own checks with a `static func self_test() ->
## Array[String]` in its kit config, returning what failed; it may await
## frames (building each level takes a few). The kit's menus add theirs there
## (KitUiSelfTest). Prints SELFTEST OK or SELFTEST FAILED and sets the exit
## code.
## Part of the kit (addons/kit).

const FRAMES := 40
const SCENES := "res://scenes"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var failures: Array[String] = []
	await get_tree().process_frame
	failures += english()
	failures += fonts()
	for scene in scenes():
		get_tree().change_scene_to_file(scene)
		for frame in FRAMES:
			await get_tree().process_frame
		if not on_stage(get_tree().current_scene, scene):
			failures.append("%s did not load" % scene)
	var config := KitConfig.find()
	if config != null and config.has_method(&"self_test"):
		var more: Variant = await config.call(&"self_test")
		if more is Array:
			var reported: Array = more
			for failure: Variant in reported:
				failures.append(str(failure))
	if failures.is_empty():
		print("SELFTEST OK")
	else:
		print("SELFTEST FAILED: " + "; ".join(failures))
	get_tree().quit(0 if failures.is_empty() else 1)


## The English the project declares answers through the engine: a text whose
## English differs from it comes back translated. A project with no English
## file has nothing to check.
static func english() -> Array[String]:
	var messages := Loc.messages("en")
	var source := ""
	for text: String in messages:
		if text != "" and str(messages[text]) != text:
			source = text
			break
	if source == "":
		var declared: PackedStringArray = ProjectSettings.get_setting(
			"internationalization/locale/translations", PackedStringArray()
		)
		return [] if declared.is_empty() else ["the English translation is not in the build"]
	var before := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var shown := Loc.t(source)
	TranslationServer.set_locale(before)
	if shown != str(messages[source]):
		return ["the English translation does not answer: %s" % source]
	return []


## The default font the project names is in the build and is the one a text
## with no font gets, not the engine's own; the licences the kit config lists
## (LICENCES) are in the build too: they are not resources, an export leaves
## them out unless include_filter names them.
static func fonts() -> Array[String]:
	var out: Array[String] = []
	var path := str(ProjectSettings.get_setting("gui/theme/custom_font", ""))
	if path != "":
		var font := load(path) as Font if ResourceLoader.exists(path) else null
		if font == null:
			out.append("%s is not in the build" % path)
		elif ThemeDB.fallback_font.get_font_name() != font.get_font_name():
			out.append("the default font is not %s" % path)
	for licence in licences():
		if not FileAccess.file_exists(licence):
			out.append("%s is not in the build" % licence)
	return out


## The files the kit config lists in LICENCES.
static func licences() -> Array[String]:
	var out: Array[String] = []
	var listed: Variant = KitConfig.constant("LICENCES", [])
	if listed is Array:
		var paths: Array = listed
		for path: Variant in paths:
			out.append(str(path))
	return out


## Every scene under res://scenes, as an exported build lists them (a scene
## is converted there and listed with a .remap beside it).
static func scenes() -> Array[String]:
	var found := {}
	for file in DirAccess.get_files_at(SCENES):
		var listed := file.trim_suffix(".remap")
		if listed.get_extension() in ["tscn", "scn"]:
			found[SCENES.path_join(listed)] = true
	var out: Array[String] = []
	for scene: String in found:
		out.append(scene)
	out.sort()
	return out


## True once `scene_path` is the scene on stage. A scene that fails to load
## leaves the previous one where it was: "there is a scene" proves nothing.
static func on_stage(current: Node, scene_path: String) -> bool:
	return current != null and current.scene_file_path == scene_path
