extends GdUnitTestSuite

## The kit's menus and their English (addons/kit_ui/locale/en.po): the file
## holds the menus' texts and nothing else, and every page shows only texts
## that have their English. Part of the kit's menus (addons/kit_ui).

const SOURCES: Array[String] = ["res://addons/kit_ui"]


func _files(dir: String, out: Array[String]) -> void:
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		if sub != "tests":
			_files(dir.path_join(sub), out)


func test_every_label_of_the_options_page_has_its_english() -> void:
	var english := Loc.messages("en")
	var missing: Array[String] = []
	for label: Variant in OptionsMenu.NAMES.values():
		if str(english.get(str(label), "")) == "":
			missing.append(str(label))
	assert_array(missing).override_failure_message("no English for %s" % [missing]).is_empty()


func test_a_text_of_the_menus_and_one_of_the_game_both_count() -> void:
	# The game's texts and the menus' are in two files: each must count.
	Loc.seen.clear()
	for text: String in [Loc.t("Reprendre"), Loc.t(str(Prefs.actions.values()[0]))]:
		assert_str(text).is_not_empty()
	assert_array(Loc.missing("en")).is_empty()
	Loc.seen.clear()


func test_the_kits_english_holds_only_the_kits_texts() -> void:
	# A game's text kept in the kit's file is translated in that game by
	# chance, and left out of every game that pulls the kit without it.
	var kit_code := ""
	var files: Array[String] = []
	for dir in SOURCES:
		_files(dir, files)
	for file in files:
		kit_code += FileAccess.get_file_as_string(file)
	var translation: Translation = load("res://addons/kit_ui/locale/en.po")
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
