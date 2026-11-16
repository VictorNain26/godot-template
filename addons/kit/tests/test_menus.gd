extends GdUnitTestSuite

## The pause menu and the options under real events: keys, gamepad buttons
## and a stick go through the Input singleton and the scene tree, as they do
## in play. Part of the kit (addons/kit).

var pause: PauseMenu
var chosen: Array[StringName] = []


func after_test() -> void:
	get_tree().paused = false
	KitSim.release_all()
	Prefs.settings = Settings.new()
	Prefs.pad = false
	Prefs.apply()
	if is_instance_valid(pause):
		pause.free()
	chosen.clear()


## A pause menu on its own, listening to the real Input.
func _load() -> void:
	pause = PauseMenu.new()
	pause.chosen.connect(func(id: StringName) -> void: chosen.append(id))
	add_child(pause)
	await KitSim.frames(get_tree(), 4)


## The row the pause menu shows as selected.
func _selected() -> String:
	for row: MenuRow in pause.find_children("*", "MenuRow", true, false):
		if row.is_visible_in_tree() and row.focused:
			return row.label
	return ""


func _legend() -> Dictionary:
	var bar: LegendBar = pause.find_children("*", "LegendBar", true, false)[0]
	var by_label := {}
	for entry: Array in bar.entries:
		by_label[entry[0]] = entry[1]
	return by_label


func test_a_gamepad_alone_gets_through_pause_and_options() -> void:
	await _load()
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	assert_bool(get_tree().paused).is_true()
	assert_str(_selected()).contains(Loc.t("Reprendre"))
	KitSim.tap(KitSim.pad(JOY_BUTTON_DPAD_DOWN))
	assert_str(_selected()).contains(Loc.t("Options"))
	KitSim.tap(KitSim.pad(JOY_BUTTON_A))
	assert_bool(pause.options.visible).is_true()
	# Start closes the options, then the pause itself.
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	assert_bool(pause.options.visible).is_false()
	assert_bool(get_tree().paused).is_true()
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	assert_bool(get_tree().paused).is_false()


func test_a_choice_of_the_game_is_handed_to_it_while_play_stays_paused() -> void:
	# The game runs its own transition (a fade, a save) before play goes on.
	await _load()
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	KitSim.tap(KitSim.key(KEY_UP))
	assert_str(_selected()).contains(Loc.t("Écran titre"))
	KitSim.tap(KitSim.key(KEY_ENTER))
	assert_array(chosen).is_equal([&"title"])
	assert_bool(get_tree().paused).is_true()
	assert_bool(pause.is_open()).is_false()


func test_a_gamepad_button_gives_up_on_choosing_a_key() -> void:
	# Only keys are rebound. A gamepad that asked for one by mistake used to
	# be held there for good: nothing it could press was a key.
	await _load()
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	var options := pause.options
	options.open()
	options.index = OptionsMenu.MAIN.find(&"keys")
	KitSim.tap(KitSim.pad(JOY_BUTTON_A))
	assert_bool(options.on_keys).is_true()
	KitSim.tap(KitSim.pad(JOY_BUTTON_A))
	assert_bool(options.listening).is_true()
	KitSim.tap(KitSim.pad(JOY_BUTTON_B))
	assert_bool(options.listening).is_false()
	assert_dict(Prefs.settings.keys).is_empty()


func test_one_push_of_the_stick_moves_one_row() -> void:
	# A stick reports every small change, and each one past the dead zone
	# reads as a press: one push used to run down the whole list.
	await _load()
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	for value: float in [0.2, 0.55, 0.8, 1.0, 0.9, 0.6]:
		KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, value))
	assert_str(_selected()).contains(Loc.t("Options"))
	# Back to rest, then a second push: one more row.
	KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, 0.0))
	assert_str(_selected()).contains(Loc.t("Options"))
	KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, 1.0))
	assert_str(_selected()).contains(Loc.t("Écran titre"))
	KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, 0.0))
	# The same in the options: one push to the left is one step of volume.
	pause.options.open()
	for value: float in [-0.6, -0.8, -1.0, -1.0, -0.7]:
		KitSim.send(KitSim.stick(JOY_AXIS_LEFT_X, value))
	assert_int(Prefs.settings.master).is_equal(Settings.new().master - 1)


func test_the_pause_legend_shows_the_menu_keys_and_the_way_back() -> void:
	# It once repeated the game's keys, "Pause" included, over a paused game.
	await _load()
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	var legend := _legend()
	assert_array(legend.keys()).contains([Loc.t("Choisir"), Loc.t("Valider"), Loc.t("Reprendre")])
	assert_array(legend[Loc.t("Reprendre")]).contains([Prefs.key_label(&"pause")])


func test_the_legends_follow_the_device_in_hand() -> void:
	await _load()
	KitSim.tap(KitSim.pad(JOY_BUTTON_START))
	assert_bool(Prefs.pad).is_true()
	assert_array(_legend()[Loc.t("Valider")]).is_equal(["A"])
	assert_array(_legend()[Loc.t("Reprendre")]).is_equal(["Start"])
	# The page of keys still names keys: it is where they are changed.
	assert_str(Prefs.key_label(&"pause", true)).is_equal(Prefs.key_name(KEY_ESCAPE))
	# A key gives the legends back to the keyboard.
	KitSim.tap(KitSim.key(KEY_DOWN))
	assert_bool(Prefs.pad).is_false()
	assert_array(_legend()[Loc.t("Valider")]).is_equal([Prefs.key_name(KEY_ENTER)])


func test_the_pointer_picks_an_entry_of_the_pause() -> void:
	# Without a window the engine gives the mouse to no Control: the rows'
	# own signals stand in for it.
	await _load()
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	var rows: Array[MenuRow] = []
	for node in pause.find_children("*", "MenuRow", true, false):
		rows.append(node as MenuRow)
	rows[1].pointed.emit()
	assert_str(_selected()).contains(Loc.t("Options"))
	rows[2].clicked.emit(1)
	assert_array(chosen).is_equal([&"title"])
