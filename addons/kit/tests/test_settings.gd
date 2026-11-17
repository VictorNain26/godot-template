extends GdUnitTestSuite

## The options: what they hold, what they do to the engine, and the menu that
## changes them. Tests never read or write the player's own settings file.
## Part of the kit (addons/kit): it uses the actions the game's kit config
## offers for rebinding, whatever they are.

const SCRATCH := "user://test_kit_settings.json"


func after_test() -> void:
	Prefs.persist = false
	Prefs.path = Prefs.PATH
	Prefs.settings = Settings.new()
	Prefs.apply()
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(SCRATCH)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


## The first action the player may rebind, and its first key.
func _action() -> StringName:
	return Prefs.actions.keys()[0]


func _first_key(action: StringName) -> Key:
	var codes: Array = Prefs.default_keys()[action]
	return codes[0]


## A key no action uses.
func _free_key() -> Key:
	var used := {}
	for codes: Array in Prefs.default_keys().values():
		for code: int in codes:
			used[code] = true
	for code: Key in [KEY_L, KEY_O, KEY_U, KEY_I, KEY_Y, KEY_N]:
		if not used.has(code):
			return code
	return KEY_F8


func test_the_game_offers_actions_to_rebind_and_a_pause_key() -> void:
	assert_dict(Prefs.actions).is_not_empty()
	assert_bool(InputMap.has_action(&"pause")).is_true()
	for action: StringName in Prefs.actions:
		assert_bool(InputMap.has_action(action)).override_failure_message(action).is_true()
		assert_array(Prefs.default_keys()[action]).override_failure_message(action).is_not_empty()


func test_volume_steps_go_from_silence_to_full_and_never_backwards() -> void:
	assert_float(Settings.volume_db(0)).is_less_equal(-80.0)
	assert_float(Settings.volume_db(Settings.STEPS)).is_equal_approx(0.0, 0.001)
	# Half the slider sounds like half: about -12 dB, not the -6 dB of a straight line.
	assert_float(Settings.volume_db(5)).is_between(-13.0, -11.0)
	for step in range(1, Settings.STEPS + 1):
		assert_float(Settings.volume_db(step)).is_greater(Settings.volume_db(step - 1))


func test_a_damaged_settings_file_falls_back_to_safe_values() -> void:
	var s := Settings.from_dict(
		{"master": 99, "music": -4, "text_scale": 7.0, "locale": "xx", "keys": {"a": "nonsense"}}
	)
	assert_int(s.master).is_equal(Settings.STEPS)
	assert_int(s.music).is_equal(0)
	assert_float(s.text_scale).is_equal(1.0)
	assert_str(s.locale).is_equal("fr")
	assert_bool(s.keys.has(&"a")).is_false()


func test_a_settings_file_with_values_of_the_wrong_type_still_loads() -> void:
	var s := Settings.from_dict(
		{"master": "loud", "shake": "yes", "fullscreen": 3, "text_scale": null, "keys": []}
	)
	assert_int(s.master).is_equal(Settings.new().master)
	assert_float(s.text_scale).is_equal(1.0)
	assert_dict(s.keys).is_empty()


func test_a_test_run_never_reads_or_writes_the_players_settings() -> void:
	# Prefs finds out on its own that the test runner started the engine.
	assert_bool(Settings.is_test_run(OS.get_cmdline_args())).is_true()
	var play := PackedStringArray(["--path", ".", "res://scenes/title.tscn"])
	assert_bool(Settings.is_test_run(play)).is_false()
	assert_bool(Prefs.persist).is_false()
	Prefs.path = SCRATCH
	Prefs.settings.master = 2
	Prefs.commit()
	assert_bool(FileAccess.file_exists(SCRATCH)).is_false()
	# The switch decides, not the absence of a window.
	Prefs.persist = true
	Prefs.commit()
	assert_bool(FileAccess.file_exists(SCRATCH)).is_true()


func test_only_the_fullscreen_option_changes_the_window() -> void:
	var plain := DisplayServer.WINDOW_MODE_WINDOWED
	var big := DisplayServer.WINDOW_MODE_MAXIMIZED
	var full := DisplayServer.WINDOW_MODE_FULLSCREEN
	var exclusive := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	assert_int(Prefs.window_mode_for(big, false)).is_equal(big)
	assert_int(Prefs.window_mode_for(plain, false)).is_equal(plain)
	assert_int(Prefs.window_mode_for(big, true)).is_equal(full)
	assert_int(Prefs.window_mode_for(full, false)).is_equal(plain)
	assert_int(Prefs.window_mode_for(exclusive, true)).is_equal(exclusive)


func test_options_survive_a_trip_through_the_file() -> void:
	var s := Prefs.settings
	s.master = 3
	s.shake = false
	s.text_scale = 1.5
	s.locale = "en"
	s.rebind(_action(), _free_key(), Prefs.default_keys())
	Prefs.save_to(SCRATCH)
	Prefs.settings = Settings.new()
	assert_bool(Prefs.load_from(SCRATCH)).is_true()
	assert_dict(Prefs.settings.to_dict()).is_equal(s.to_dict())
	assert_bool(Prefs.load_from("user://no_such_file.json")).is_false()


func test_taking_a_key_never_leaves_an_action_without_one() -> void:
	var defaults := Prefs.default_keys()
	var s := Settings.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var actions := defaults.keys()
	var pool: Array[Key] = []
	for codes: Array in defaults.values():
		for code: int in codes:
			pool.append(code as Key)
	pool.append(_free_key())
	for i in 400:
		var picked: StringName = actions[rng.randi() % actions.size()]
		s.rebind(picked, pool[rng.randi() % pool.size()], defaults)
		var layout := s.bindings(defaults)
		var holder := {}
		for action: StringName in layout:
			(
				assert_array(layout[action])
				. override_failure_message("%s lost its keys" % action)
				. is_not_empty()
			)
			for code: int in layout[action]:
				(
					assert_bool(holder.has(code))
					. override_failure_message(
						"key %d is on %s and %s" % [code, holder.get(code), action]
					)
					. is_false()
				)
				holder[code] = action


func test_a_new_key_works_at_once_and_the_old_one_stops() -> void:
	var action := _action()
	var old := _first_key(action)
	var fresh := _free_key()
	assert_bool(InputMap.event_is_action(_key(old), action)).is_true()
	assert_bool(Prefs.rebind(action, fresh)).is_true()
	assert_bool(InputMap.event_is_action(_key(fresh), action)).is_true()
	# No key at all, or an action that is not offered: nothing is done, and said so.
	assert_bool(Prefs.rebind(action, KEY_NONE)).is_false()
	assert_bool(Prefs.rebind(&"pause", KEY_O)).is_false()
	# Escape closes menus: it cannot be given away.
	assert_bool(Prefs.rebind(action, KEY_ESCAPE)).is_false()
	Prefs.reset_keys()
	assert_bool(InputMap.event_is_action(_key(old), action)).is_true()
	assert_bool(InputMap.event_is_action(_key(fresh), action)).is_false()


func test_volume_reaches_the_audio_buses() -> void:
	for bus: StringName in [&"Music", &"Sfx"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	Prefs.settings.music = 0
	Prefs.settings.sfx = 5
	Prefs.apply()
	var music := AudioServer.get_bus_index(&"Music")
	var sfx := AudioServer.get_bus_index(&"Sfx")
	assert_bool(AudioServer.is_bus_mute(music)).is_true()
	assert_float(AudioServer.get_bus_volume_db(sfx)).is_equal_approx(Settings.volume_db(5), 0.01)
	assert_bool(AudioServer.is_bus_mute(sfx)).is_false()


func test_text_size_scales_what_is_drawn() -> void:
	assert_int(Prefs.px(24)).is_equal(24)
	Prefs.settings.text_scale = 1.5
	assert_int(Prefs.px(24)).is_equal(36)


func test_the_menu_changes_options_and_takes_a_new_key() -> void:
	var menu: OptionsMenu = auto_free(OptionsMenu.new())
	add_child(menu)
	var closed := [false]
	menu.closed.connect(func() -> void: closed[0] = true)
	menu.open()
	assert_array(menu.rows()).is_equal(OptionsMenu.MAIN)
	menu.change(-1)
	assert_int(Prefs.settings.master).is_equal(Settings.new().master - 1)
	menu.index = OptionsMenu.MAIN.find(&"text")
	menu.change(1)
	assert_float(Prefs.settings.text_scale).is_equal(1.25)
	assert_str(menu.row_text(&"text")).contains("125")
	menu.index = OptionsMenu.MAIN.find(&"shake")
	menu.accept()
	assert_bool(Prefs.settings.shake).is_false()
	menu.index = OptionsMenu.MAIN.find(&"keys")
	menu.accept()
	assert_bool(menu.on_keys).is_true()
	assert_int(menu.rows().size()).is_equal(Prefs.actions.size() + 2)
	var action := _action()
	var fresh := _free_key()
	menu.index = menu.rows().find(action)
	menu.accept()
	assert_bool(menu.listening).is_true()
	menu.take_key(fresh)
	assert_bool(menu.listening).is_false()
	assert_bool(InputMap.event_is_action(_key(fresh), action)).is_true()
	menu.back()
	assert_bool(menu.on_keys).is_false()
	menu.back()
	assert_bool(closed[0]).is_true()
	assert_bool(menu.visible).is_false()
