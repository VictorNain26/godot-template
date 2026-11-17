extends GdUnitTestSuite

## French is the source language; every other loaded language holds the
## same texts. Nothing the player sees is left in one language: each text
## written as Loc.t("...") in the game's code or the kit's, and each label of
## the kit config, has its translation. Part of the kit (addons/kit).

const SOURCES: Array[String] = ["res://src", "res://scenes", "res://scripts", "res://addons/kit"]
## Other addons scanned too: the kit's menus, when the game keeps them.
const ADDONS := "res://addons"
const KIT_PREFIX := "kit_"
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
## kit config. Texts that go through a variable are checked where they are
## made (the kit's menus test their own).
func _shown() -> Array[String]:
	var files: Array[String] = []
	var dirs := SOURCES.duplicate()
	for sub in DirAccess.get_directories_at(ADDONS):
		if sub.begins_with(KIT_PREFIX):
			dirs.append(ADDONS.path_join(sub))
	for dir: String in dirs:
		_files(dir, files)
	var calls := RegEx.create_from_string(CALL)
	var out := {}
	for file in files:
		for hit in calls.search_all(FileAccess.get_file_as_string(file)):
			out[hit.get_string(1).c_unescape()] = true
	for label: Variant in Prefs.actions.values():
		out[str(label)] = true
	for entry: Array in Prefs.help_entries:
		out[str(entry[0])] = true
	var texts: Array[String] = []
	for text: String in out:
		texts.append(text)
	return texts


func test_the_search_finds_the_texts_the_code_shows() -> void:
	# The regex is what finds them: a sample call is found, with its escapes.
	var hit := RegEx.create_from_string(CALL).search('x = Loc.t( "Un \\"mot\\"")')
	assert_object(hit).is_not_null()
	assert_str(hit.get_string(1).c_unescape()).is_equal('Un "mot"')
	assert_int(_shown().size()).is_greater(0)


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


func test_a_text_shown_with_its_english_is_not_missing() -> void:
	Loc.seen.clear()
	assert_str(Loc.t(str(Prefs.actions.values()[0]))).is_not_empty()
	assert_array(Loc.missing("en")).is_empty()
	Loc.t("Un texte qui n'existe dans aucune langue")
	assert_array(Loc.missing("en")).is_equal(["Un texte qui n'existe dans aucune langue"])
	Loc.seen.clear()
