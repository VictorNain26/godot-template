extends GdUnitTestSuite

## The kit's options menu changes the options and takes a new key. Part of
## the kit's menus (addons/kit_ui): it uses the actions the game's kit config
## offers for rebinding, whatever they are.


func after_test() -> void:
	Prefs.persist = false
	Prefs.path = Prefs.PATH
	Prefs.settings = Settings.new()
	Prefs.apply()


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


## The first action the player may rebind.
func _action() -> StringName:
	return Prefs.actions.keys()[0]


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
