extends RefCounted
## The kit config of a game that writes its own menus: no skin, no
## addons/kit_ui. Used by tools/kit_core_check.sh.

const ACTIONS := {&"interact": "Sauter"}
const FIXED_ACTIONS: Array[StringName] = [&"pause"]
const HELP: Array[Array] = [["Sauter", [&"interact"]]]
const LICENCES: Array[String] = []


static func self_test() -> Array[String]:
	return []


## Clicks the game's own menu: its one button counts the clicks.
static func mouse_check(check: MouseCheck) -> void:
	var menu: OwnMenu = (load("res://scenes/own_menu.tscn") as PackedScene).instantiate()
	check.add_child(menu)
	await check.frames(6)
	await check.click(menu.play.get_global_rect().get_center())
	check.expect(menu.clicks == 1, "a click on the game's own button does not reach it")
	menu.free()
