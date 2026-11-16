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
	# Whichever demos the game kept (the new-game skill drops one).
	var demos: Array[String] = []
	for file in DirAccess.get_files_at("res://scenes"):
		if file.begins_with("main_") and file.ends_with(".tscn"):
			demos.append("res://scenes/" + file)
	assert_array(demos).is_not_empty()
	for path: String in demos:
		var root: Node = auto_free((load(path) as PackedScene).instantiate())
		assert_object(root.get_node_or_null("Pause")).override_failure_message(path).is_instanceof(
			PauseMenu
		)


func test_the_title_asks_only_for_texts_with_their_english() -> void:
	# Its entries reach Loc.t through a variable, out of the kit's search of
	# the code: ask Loc what the screen showed.
	Loc.seen.clear()
	title.queue_redraw()
	await KitSim.frames(get_tree(), 2)
	assert_array(Loc.seen.keys()).contains(["Commencer"])
	assert_array(Loc.missing("en")).is_empty()
	Loc.seen.clear()


func test_the_title_lets_the_pointer_through_to_its_menu() -> void:
	# A full-screen Control stops every mouse event before _unhandled_input:
	# the pointer did nothing on the title. Without a window no mouse event
	# reaches a Control, so this checks the setting; a real pointer goes
	# through it in the window (scratch probe, and mise run mouse-check for
	# the kit's menus).
	assert_int(title.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
