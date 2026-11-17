class_name KitUiSelfTest
extends RefCounted
## What an exported build checks about the kit's menus: their two typefaces
## and the licences of both are in the build, and a text that names no font
## gets the reading face, not the engine's own. A game that keeps these menus
## returns run() from its kit config's self_test(). Part of the kit's menus
## (addons/kit_ui).


static func run() -> Array[String]:
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
