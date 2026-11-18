extends GdUnitTestSuite

## What an exported build checks about itself (addons/kit/dev/self_test.gd) is
## only worth its verdict if the checks can fail. The export itself is run by
## `mise run export-smoke`, not here. Part of the kit (addons/kit).

const SELF_TEST := "res://addons/kit/dev/self_test.gd"


func test_the_self_test_tells_a_scene_that_did_not_load() -> void:
	# A scene that fails to load leaves the previous one on stage: asking
	# whether there is a scene at all could never report it.
	var self_test: GDScript = load(SELF_TEST)
	var previous: Node = auto_free(Node.new())
	previous.scene_file_path = "res://scenes/a.tscn"
	assert_bool(self_test.call(&"on_stage", previous, "res://scenes/b.tscn")).is_false()
	assert_bool(self_test.call(&"on_stage", previous, "res://scenes/a.tscn")).is_true()
	assert_bool(self_test.call(&"on_stage", null, "res://scenes/b.tscn")).is_false()


func test_the_self_test_visits_every_scene_of_the_game() -> void:
	var self_test: GDScript = load(SELF_TEST)
	var scenes: Array[String] = self_test.call(&"scenes")
	assert_array(scenes).is_not_empty()
	for file in DirAccess.get_files_at("res://scenes"):
		if file.get_extension() == "tscn":
			assert_array(scenes).contains(["res://scenes/" + file])


func test_the_fonts_the_build_needs_are_found() -> void:
	var self_test: GDScript = load(SELF_TEST)
	var missing: Array[String] = self_test.call(&"fonts")
	assert_array(missing).is_empty()


func test_the_licences_checked_are_the_ones_the_kit_config_lists() -> void:
	var self_test: GDScript = load(SELF_TEST)
	var listed: Array[String] = self_test.call(&"licences")
	var declared: Array = KitConfig.constant("LICENCES", [])
	assert_int(listed.size()).is_equal(declared.size())
	for path: Variant in declared:
		assert_array(listed).contains([str(path)])


func test_the_english_of_the_project_answers() -> void:
	var self_test: GDScript = load(SELF_TEST)
	var missing: Array[String] = self_test.call(&"english")
	assert_array(missing).is_empty()


func test_the_error_log_keeps_nothing_until_started() -> void:
	# Tests do not run under --selftest: Prefs did not start it.
	assert_array(ErrorLog.errors()).is_empty()


func test_a_constant_the_kit_config_lacks_gives_the_fallback() -> void:
	assert_str(str(KitConfig.constant("NO_SUCH_CONSTANT", "fallback"))).is_equal("fallback")
	assert_object(KitConfig.find()).is_not_null()
