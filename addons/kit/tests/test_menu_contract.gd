extends GdUnitTestSuite

## Every menu the game lists in its kit config (menus()) keeps MenuContract,
## whoever drew it: real keys (arrows and the game's move keys), pad buttons
## and the stick move through it one item at a time and choose; its items
## are on screen, big enough to point at and apart; its texts have their
## English; its text is big enough and stands out from what it lies on. The
## pointer is checked under Xvfb by MouseCheck.menus(). Part of the kit
## (addons/kit).


func after_test() -> void:
	KitSim.release_all()
	get_tree().paused = false


func _builders() -> Array[Callable]:
	var config := KitConfig.find()
	var out: Array[Callable] = []
	if config != null and config.has_method(&"menus"):
		var listed: Array = config.call(&"menus")
		for build: Callable in listed:
			out.append(build)
	return out


## The menus that offer the whole contract: the others fail
## test_each_menu_offers_the_contract, and the rest is not tried on them.
func _conforming() -> Array[Callable]:
	var out: Array[Callable] = []
	for build in _builders():
		var menu: Node = build.call()
		if MenuContract.missing(menu).is_empty():
			out.append(build)
		menu.free()
	return out


## Builds the menu, puts it on stage in dry run and opens it.
func _open(build: Callable) -> Node:
	var menu: Node = build.call()
	add_child(menu)
	await KitSim.frames(get_tree(), 3)
	menu.set(&"menu_dry_run", true)
	menu.call(&"menu_open")
	await KitSim.frames(get_tree(), 3)
	return menu


func _close(menu: Node) -> void:
	get_tree().paused = false
	menu.free()


func _name(menu: Node) -> String:
	var script: Script = menu.get_script()
	return script.resource_path.get_file() if script != null else menu.get_class()


func test_the_kit_config_lists_the_game_menus() -> void:
	var config := KitConfig.find()
	assert_object(config).is_not_null()
	(
		assert_bool(config.has_method(&"menus"))
		. override_failure_message("the kit config has no menus(): nothing checks the game's menus")
		. is_true()
	)
	assert_array(_builders()).is_not_empty()


func test_each_menu_offers_the_contract() -> void:
	for build in _builders():
		var menu: Node = build.call()
		var missing := MenuContract.missing(menu)
		(
			assert_array(missing)
			. override_failure_message("%s: %s" % [_name(menu), ", ".join(missing)])
			. is_empty()
		)
		menu.free()


func test_each_menu_is_on_screen_big_enough_to_point_at_and_apart() -> void:
	for build in _conforming():
		var menu := await _open(build)
		var rects: Array[Rect2] = menu.call(&"menu_rects")
		var problems := MenuContract.layout_problems(rects, get_viewport().get_visible_rect())
		(
			assert_array(problems)
			. override_failure_message("%s: %s" % [_name(menu), "; ".join(problems)])
			. is_empty()
		)
		_close(menu)


func test_each_menu_text_is_big_enough_and_stands_out() -> void:
	for build in _conforming():
		var menu: Node = build.call()
		var style: Dictionary = menu.call(&"menu_text_style")
		var problems := MenuContract.style_problems(style)
		(
			assert_array(problems)
			. override_failure_message("%s: %s" % [_name(menu), "; ".join(problems)])
			. is_empty()
		)
		menu.free()


func test_each_menu_text_has_its_english() -> void:
	var english := Loc.messages("en")
	for build in _conforming():
		var menu := await _open(build)
		var texts: Array[String] = menu.call(&"menu_texts")
		var rects: Array[Rect2] = menu.call(&"menu_rects")
		(
			assert_int(texts.size())
			. override_failure_message(
				"%s: %d texts for %d items" % [_name(menu), texts.size(), rects.size()]
			)
			. is_equal(rects.size())
		)
		if not english.is_empty():
			for text in texts:
				(
					assert_str(str(english.get(text, "")))
					. override_failure_message("%s: no English for %s" % [_name(menu), text])
					. is_not_empty()
				)
		_close(menu)


## One step of `event` (pressed then let go): the selection moves by `by`,
## wrapping or staying at an end.
func _step(menu: Node, down: InputEvent, by: int, how: String) -> void:
	var rects: Array[Rect2] = menu.call(&"menu_rects")
	var count := rects.size()
	var from: int = menu.call(&"menu_index")
	KitSim.tap(down)
	await KitSim.frames(get_tree(), 2)
	var to: int = menu.call(&"menu_index")
	var allowed := MenuContract.steps_to(from, by, count)
	var told := "%s: %s from item %d went to %d" % [_name(menu), how, from, to]
	assert_bool(allowed.has(to)).override_failure_message(told).is_true()


## The stick pushed past the press threshold, then back to rest.
func _push(menu: Node, value: float, how: String) -> void:
	var rects: Array[Rect2] = menu.call(&"menu_rects")
	var count := rects.size()
	var from: int = menu.call(&"menu_index")
	KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, value))
	KitSim.send(KitSim.stick(JOY_AXIS_LEFT_Y, 0.0))
	await KitSim.frames(get_tree(), 2)
	var to: int = menu.call(&"menu_index")
	var allowed := MenuContract.steps_to(from, 1 if value > 0 else -1, count)
	var told := "%s: %s from item %d went to %d" % [_name(menu), how, from, to]
	assert_bool(allowed.has(to)).override_failure_message(told).is_true()


## The game's own key for `action`, if it binds one.
func _game_key(action: StringName) -> InputEventKey:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return KitSim.key(key.physical_keycode)
	return null


func test_keys_pad_and_stick_move_through_each_menu() -> void:
	for build in _conforming():
		var menu := await _open(build)
		var rects: Array[Rect2] = menu.call(&"menu_rects")
		var count := rects.size()
		for i in count:
			await _step(menu, KitSim.key(KEY_DOWN), 1, "the down arrow")
		for i in count:
			await _step(menu, KitSim.key(KEY_UP), -1, "the up arrow")
		var down := _game_key(&"move_down")
		var up := _game_key(&"move_up")
		if down != null and up != null:
			await _step(menu, down, 1, "the game's down key")
			await _step(menu, up, -1, "the game's up key")
		await _step(menu, KitSim.pad(JOY_BUTTON_DPAD_DOWN), 1, "the pad's down")
		await _step(menu, KitSim.pad(JOY_BUTTON_DPAD_UP), -1, "the pad's up")
		await _push(menu, 1.0, "the stick down")
		await _push(menu, -1.0, "the stick up")
		_close(menu)


func test_enter_and_the_pad_choose_the_selected_item() -> void:
	for build in _conforming():
		for accept: InputEvent in [KitSim.key(KEY_ENTER), KitSim.pad(JOY_BUTTON_A)]:
			var menu := await _open(build)
			KitSim.tap(KitSim.key(KEY_DOWN))
			await KitSim.frames(get_tree(), 2)
			var selected: int = menu.call(&"menu_index")
			var chosen: Array[int] = []
			menu.connect(&"menu_chosen", func(index: int) -> void: chosen.append(index))
			KitSim.tap(accept)
			await KitSim.frames(get_tree(), 2)
			(
				assert_array(chosen)
				. override_failure_message(
					"%s: %s chose %s, not [%d]" % [_name(menu), accept.as_text(), chosen, selected]
				)
				. is_equal([selected])
			)
			_close(menu)


func test_the_contract_checks_catch_what_they_check() -> void:
	var screen := Rect2(0, 0, 1280, 720)
	assert_array(MenuContract.layout_problems([] as Array[Rect2], screen)).is_not_empty()
	var off: Array[Rect2] = [Rect2(1270, 10, 100, 40)]
	assert_array(MenuContract.layout_problems(off, screen)).is_not_empty()
	var small: Array[Rect2] = [Rect2(10, 10, 100, 20)]
	assert_array(MenuContract.layout_problems(small, screen)).is_not_empty()
	var overlap: Array[Rect2] = [Rect2(10, 10, 100, 40), Rect2(10, 40, 100, 40)]
	assert_array(MenuContract.layout_problems(overlap, screen)).is_not_empty()
	var fine: Array[Rect2] = [Rect2(10, 10, 100, 40), Rect2(10, 60, 100, 40)]
	assert_array(MenuContract.layout_problems(fine, screen)).is_empty()
	var grey := [[Color("777777"), Color.WHITE]]
	assert_array(MenuContract.style_problems({"size": 24, "pairs": grey})).is_not_empty()
	var dark := [[Color("767676"), Color.WHITE]]
	assert_array(MenuContract.style_problems({"size": 24, "pairs": dark})).is_empty()
	assert_array(MenuContract.style_problems({"size": 18, "pairs": dark})).is_not_empty()
	assert_array(MenuContract.style_problems({"size": 24, "pairs": []})).is_not_empty()
	assert_array(MenuContract.steps_to(2, 1, 3)).is_equal([0, 2])
	assert_array(MenuContract.steps_to(0, 1, 3)).is_equal([1])
	assert_array(MenuContract.missing(RefCounted.new())).is_not_empty()
