extends Node
## Clicks through the kit's menus with real mouse events: the options page
## and the pause menu. Without a window the engine gives the mouse to no
## Control, so this runs where tests cannot, under Xvfb (mise run
## mouse-check). Prints MOUSE CHECK OK or MOUSE CHECK FAILED and sets the
## exit code. Part of the kit (addons/kit).

var _failures: Array[String] = []


func _ready() -> void:
	Prefs.persist = false
	Prefs.settings = Settings.new()
	Prefs.apply()
	await _options()
	await _pause()
	print(
		"MOUSE CHECK OK" if _failures.is_empty() else "MOUSE CHECK FAILED: " + "; ".join(_failures)
	)
	get_tree().quit(0 if _failures.is_empty() else 1)


## In the options: the pointer selects, a volume goes up and down by clicks,
## Back closes the page.
func _options() -> void:
	var menu := OptionsMenu.new()
	add_child(menu)
	menu.open()
	await _frames(6)
	var rows := _rows(menu)
	await _move(rows[2].get_global_rect().get_center())
	_expect(menu.index == 2, "the pointer over a row does not select it")
	var row := rows[0]
	var origin := row.get_global_rect().position
	var y := row.size.y * 0.5
	var before := Prefs.settings.volume(&"master")
	await _click(origin + Vector2(row.value_span.y - 4.0, y))
	_expect(
		Prefs.settings.volume(&"master") == before + 1,
		"a click right of the volume does not raise it"
	)
	await _click(origin + Vector2(row.value_span.x + 4.0, y))
	_expect(
		Prefs.settings.volume(&"master") == before, "a click left of the volume does not lower it"
	)
	await _click(rows[OptionsMenu.MAIN.find(&"back")].get_global_rect().get_center())
	_expect(not menu.visible, "a click on Back does not close the options")
	menu.free()


## In the pause: a click opens the options, another resumes play.
func _pause() -> void:
	var pause := PauseMenu.new()
	add_child(pause)
	await _frames(6)
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	await _frames(4)
	_expect(get_tree().paused, "Escape does not pause")
	var rows := _rows(pause)
	await _click(rows[1].get_global_rect().get_center())
	_expect(pause.options.visible, "a click on Options in the pause does not open them")
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	await _frames(4)
	await _click(rows[0].get_global_rect().get_center())
	await _frames(6)
	_expect(not get_tree().paused, "a click on Resume does not resume")
	pause.free()


func _rows(owner_node: Node) -> Array[MenuRow]:
	var out: Array[MenuRow] = []
	for node in owner_node.find_children("*", "MenuRow", true, false):
		if (node as MenuRow).visible:
			out.append(node as MenuRow)
	return out


func _move(at: Vector2) -> void:
	KitSim.send(KitSim.point(at))
	await _frames(2)


func _click(at: Vector2) -> void:
	await _move(at)
	KitSim.send(KitSim.click(at))
	KitSim.send(KitSim.click(at, false))
	await _frames(3)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _expect(ok: bool, failure: String) -> void:
	if not ok:
		_failures.append(failure)
