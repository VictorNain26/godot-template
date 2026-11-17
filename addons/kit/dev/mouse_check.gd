class_name MouseCheck
extends Node
## Clicks through the game's menus with real mouse events. Without a window
## the engine gives the mouse to no Control, so this runs where tests cannot,
## under Xvfb (mise run mouse-check). What to click is the game's: its kit
## config's `static func mouse_check(check: MouseCheck)` opens its menus and
## drives them with move(), click(), frames() and expect(); the kit's menus
## give theirs in KitUiMouseCheck. A config without one fails: a game whose
## menus nobody clicks would otherwise pass. Prints MOUSE CHECK OK or MOUSE
## CHECK FAILED and sets the exit code. Part of the kit (addons/kit).

var _failures: Array[String] = []


func _ready() -> void:
	Prefs.persist = false
	Prefs.settings = Settings.new()
	Prefs.apply()
	var config := KitConfig.find()
	if config == null or not config.has_method(&"mouse_check"):
		expect(false, "the kit config has no mouse_check(check): nothing was clicked")
	else:
		await config.call(&"mouse_check", self)
	print(
		"MOUSE CHECK OK" if _failures.is_empty() else "MOUSE CHECK FAILED: " + "; ".join(_failures)
	)
	get_tree().quit(0 if _failures.is_empty() else 1)


## Moves the pointer to `at`, in the window's coordinates.
func move(at: Vector2) -> void:
	KitSim.send(KitSim.point(at))
	await frames(2)


## A left click at `at`, the pointer moved there first.
func click(at: Vector2) -> void:
	await move(at)
	KitSim.send(KitSim.click(at))
	KitSim.send(KitSim.click(at, false))
	await frames(3)


func frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


## Records `failure` unless `ok`.
func expect(ok: bool, failure: String) -> void:
	if not ok:
		_failures.append(failure)


## What failed so far.
func failures() -> Array[String]:
	return _failures.duplicate()
