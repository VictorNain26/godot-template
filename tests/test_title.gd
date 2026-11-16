extends GdUnitTestSuite

## The title screen: its menu under real keys, and the options it opens.

var title: Title


func before_test() -> void:
	title = auto_free((load("res://scenes/title.tscn") as PackedScene).instantiate())
	add_child(title)
	await KitSim.frames(get_tree(), 3)


func after_test() -> void:
	KitSim.release_all()
	Prefs.settings = Settings.new()
	Prefs.apply()


func test_the_menu_starts_on_its_first_entry_and_wraps_both_ways() -> void:
	assert_int(title.get("_index")).is_equal(0)
	KitSim.tap(KitSim.key(KEY_UP))
	var entries: Array[String] = title.get("_entries")
	assert_int(title.get("_index")).is_equal(entries.size() - 1)
	KitSim.tap(KitSim.key(KEY_DOWN))
	assert_int(title.get("_index")).is_equal(0)


func test_options_open_from_the_title_and_close_back_to_it() -> void:
	KitSim.tap(KitSim.key(KEY_DOWN))
	KitSim.tap(KitSim.key(KEY_ENTER))
	var menu: OptionsMenu = title.get("_menu")
	assert_bool(menu.visible).is_true()
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	assert_bool(menu.visible).is_false()


func test_the_menu_panel_is_where_the_pointer_finds_its_entries() -> void:
	await KitSim.frames(get_tree(), 2)
	var panel: Rect2 = title.get("_panel")
	assert_bool(panel.has_area()).is_true()
	var size := Prefs.px(UiStyle.MENU)
	var entries: Array[String] = title.get("_entries")
	var row := size + UiStyle.ROW_PAD * 2.0 + UiStyle.UNIT * 0.5
	for i in entries.size():
		var at := panel.position + Vector2(panel.size.x * 0.5, UiStyle.UNIT * 2.0 + row * (i + 0.5))
		assert_int(UiDraw.menu_hit(panel, entries.size(), size, at)).is_equal(i)


func test_each_demo_carries_the_pause_menu() -> void:
	for path: String in ["res://scenes/main_2d.tscn", "res://scenes/main_3d.tscn"]:
		var root: Node = auto_free((load(path) as PackedScene).instantiate())
		assert_object(root.get_node_or_null("Pause")).override_failure_message(path).is_instanceof(
			PauseMenu
		)
