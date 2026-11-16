extends GdUnitTestSuite

## French is the source language; every other loaded language holds the
## same texts. Nothing the player sees is left in one language: each text
## written as Loc.t("...") in the game's code or the kit's, and each label of
## the kit config, has its translation. Part of the kit (addons/kit).

const SOURCES: Array[String] = ["res://src", "res://scenes", "res://scripts", "res://addons/kit"]
const CALL := 'Loc\\.t\\(\\s*"((?:[^"\\\\]|\\\\.)*)"'


func _files(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		if sub != "tests":
			_files(dir.path_join(sub), out)


## Every text the code hands to Loc.t as written, plus the labels of the
## kit config and of the options page.
func _shown() -> Array[String]:
	var files: Array[String] = []
	for dir in SOURCES:
		_files(dir, files)
	var calls := RegEx.create_from_string(CALL)
	var out := {}
	for file in files:
		for hit in calls.search_all(FileAccess.get_file_as_string(file)):
			out[hit.get_string(1).c_unescape()] = true
	for label: Variant in Prefs.actions.values() + OptionsMenu.NAMES.values():
		out[str(label)] = true
	for entry: Array in Prefs.help_entries:
		out[str(entry[0])] = true
	var texts: Array[String] = []
	for text: String in out:
		texts.append(text)
	return texts


func test_the_code_shows_texts_through_loc() -> void:
	assert_int(_shown().size()).is_greater(10)


func test_every_shown_text_has_its_english() -> void:
	var english := Loc.messages("en")
	assert_dict(english).is_not_empty()
	var missing: Array[String] = []
	for text in _shown():
		# A text that is only a format, a number or punctuation needs none.
		if (
			text.strip_edges().is_empty()
			or not RegEx.create_from_string("[A-Za-zÀ-ÿ]").search(text)
		):
			continue
		if str(english.get(text, "")) == "":
			missing.append(text)
	assert_array(missing).override_failure_message("no English for %s" % [missing]).is_empty()


func test_the_project_falls_back_to_french() -> void:
	# Without it, Godot falls back to English and a French player reads English.
	assert_str(str(ProjectSettings.get_setting("internationalization/locale/fallback"))).is_equal(
		"fr"
	)


func test_a_text_shown_with_its_english_in_any_file_is_not_missing() -> void:
	# The game's texts and the kit's are in two files: each must count.
	Loc.seen.clear()
	for text: String in [Loc.t("Reprendre"), Loc.t(str(Prefs.actions.values()[0]))]:
		assert_str(text).is_not_empty()
	assert_array(Loc.missing("en")).is_empty()
	Loc.t("Un texte qui n'existe dans aucune langue")
	assert_array(Loc.missing("en")).is_equal(["Un texte qui n'existe dans aucune langue"])
	Loc.seen.clear()


func test_the_kits_english_holds_only_the_kits_texts() -> void:
	# A game's text kept in the kit's file is translated in that game by
	# chance, and left out of every game that pulls the kit without it.
	var kit_code := ""
	var files: Array[String] = []
	_files("res://addons/kit", files)
	for file in files:
		kit_code += FileAccess.get_file_as_string(file)
	var translation: Translation = load("res://addons/kit/locale/en.po")
	var foreign: Array[String] = []
	for message: StringName in translation.get_message_list():
		var text := str(message)
		if text != "" and not kit_code.contains('"%s"' % text.replace('"', '\\"')):
			foreign.append(text)
	assert_array(foreign).override_failure_message("not the kit's: %s" % [foreign]).is_empty()


func test_the_kits_menus_ask_only_for_texts_with_their_english() -> void:
	# Texts handed to Loc.t through a variable escape the search above: open
	# every page of the kit's menus and ask Loc what they showed.
	Loc.seen.clear()
	var pause: PauseMenu = auto_free(PauseMenu.new())
	add_child(pause)
	await get_tree().process_frame
	pause.options.open()
	for row in pause.options.rows():
		pause.options.row_text(row)
	pause.options.on_keys = true
	pause.options.listening = true
	pause.options.refresh()
	pause.legend()
	await get_tree().process_frame
	assert_array(Loc.missing("en")).is_empty()
	Loc.seen.clear()
