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


## Every message of every translation file the project declares, in `locale`.
static func messages(locale: String) -> Dictionary:
	var out := {}
	var files: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray()
	)
	for path in files:
		var translation := load(path) as Translation
		if translation == null or translation.locale != locale:
			continue
		for message in translation.get_message_list():
			out[str(message)] = str(translation.get_message(message))
	return out


func test_every_shown_text_has_its_english() -> void:
	var english := messages("en")
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
