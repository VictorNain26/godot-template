class_name KitUiMouseCheck
extends RefCounted
## The clicks `mise run mouse-check` makes on the kit's menus: the options
## page and the pause menu. A game that keeps these menus calls run() from
## its kit config's mouse_check(check). Part of the kit's menus (addons/kit_ui).


static func run(check: MouseCheck) -> void:
	await options(check)
	await pause(check)


## In the options: the pointer selects, a volume goes up and down by clicks,
## Back closes the page.
static func options(check: MouseCheck) -> void:
	var menu := OptionsMenu.new()
	check.add_child(menu)
	menu.open()
	await check.frames(6)
	var rows := visible_rows(menu)
	await check.move(rows[2].get_global_rect().get_center())
	check.expect(menu.index == 2, "the pointer over a row does not select it")
	var row := rows[0]
	var origin := row.get_global_rect().position
	var y := row.size.y * 0.5
	var before := Prefs.settings.volume(&"master")
	await check.click(origin + Vector2(row.value_span.y - 4.0, y))
	check.expect(
		Prefs.settings.volume(&"master") == before + 1,
		"a click right of the volume does not raise it"
	)
	await check.click(origin + Vector2(row.value_span.x + 4.0, y))
	check.expect(
		Prefs.settings.volume(&"master") == before, "a click left of the volume does not lower it"
	)
	await check.click(rows[OptionsMenu.MAIN.find(&"back")].get_global_rect().get_center())
	check.expect(not menu.visible, "a click on Back does not close the options")
	menu.free()


## In the pause: a click opens the options, another resumes play.
static func pause(check: MouseCheck) -> void:
	var menu := PauseMenu.new()
	check.add_child(menu)
	await check.frames(6)
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	await check.frames(4)
	check.expect(check.get_tree().paused, "Escape does not pause")
	var rows := visible_rows(menu)
	await check.click(rows[1].get_global_rect().get_center())
	check.expect(menu.options.visible, "a click on Options in the pause does not open them")
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	await check.frames(4)
	await check.click(rows[0].get_global_rect().get_center())
	# Resume waits two physics ticks; an empty scene draws many frames in that time.
	for i in 4:
		await check.get_tree().physics_frame
	check.expect(not check.get_tree().paused, "a click on Resume does not resume")
	menu.free()


## The rows of `menu` that are on screen.
static func visible_rows(menu: Node) -> Array[MenuRow]:
	var out: Array[MenuRow] = []
	for node in menu.find_children("*", "MenuRow", true, false):
		if (node as MenuRow).visible:
			out.append(node as MenuRow)
	return out
