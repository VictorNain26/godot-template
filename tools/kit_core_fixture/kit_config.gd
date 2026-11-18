extends RefCounted
## The kit config of a game that writes its own menus: no skin, no
## addons/kit_ui. Used by tools/kit_core_check.sh.

const ACTIONS := {&"interact": "Sauter"}
const FIXED_ACTIONS: Array[StringName] = [&"pause"]
const HELP: Array[Array] = [["Sauter", [&"interact"]]]
const LICENCES: Array[String] = []


static func self_test() -> Array[String]:
	return []


## The game's menus, checked against MenuContract.
static func menus() -> Array[Callable]:
	return [
		func() -> Node: return (load("res://scenes/own_menu.tscn") as PackedScene).instantiate()
	]


## Clicks the game's own menu: every button pointed at and clicked.
static func mouse_check(check: MouseCheck) -> void:
	await check.menus()
