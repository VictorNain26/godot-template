class_name Settings
extends RefCounted

## The player's options, as plain data: clamped on the way in, saved apart
## from progress. Nothing here touches the engine; Prefs applies it.

const STEPS := 10
const TEXT_SCALES: Array[float] = [1.0, 1.25, 1.5]
const LOCALES: Array[String] = ["fr", "en"]
const LOCALE_NAMES := {"fr": "Français", "en": "English"}
const VOLUMES: Array[StringName] = [&"master", &"music", &"sfx"]

var master := 8
var music := 8
var sfx := 8
var fullscreen := false
var shake := true
var text_scale := 1.0
var locale := "fr"
## action -> physical keycode the player chose. An action left out keeps its
## default keys. The order matters: a later choice wins a key over an earlier one.
var keys: Dictionary = {}


## Loudness of a volume step. The curve is squared because hearing is not
## linear: step 5 of 10 sounds like half, not like the -6 dB a straight line gives.
static func volume_db(step: int) -> float:
	if step <= 0:
		return -80.0
	return linear_to_db(pow(clampf(float(step) / STEPS, 0.0, 1.0), 2.0))


## French for a French system, English for everyone else.
static func pick_locale(system_language: String) -> String:
	return "fr" if system_language == "fr" else "en"


## True when the engine runs the tests or a recording rather than the game.
## Nothing of the player's is read or written then (Prefs, Game).
static func is_test_run(arguments: PackedStringArray) -> bool:
	for argument in arguments:
		if argument.contains("gdUnit4") or argument.contains("res://tests/"):
			return true
	return false


## Reads a saved dictionary. A value of the wrong type (a hand-edited file, a
## file from another version) falls back to its default like a missing one.
static func from_dict(data: Dictionary) -> Settings:
	var s := Settings.new()
	s.master = clampi(_whole(data.get("master"), s.master), 0, STEPS)
	s.music = clampi(_whole(data.get("music"), s.music), 0, STEPS)
	s.sfx = clampi(_whole(data.get("sfx"), s.sfx), 0, STEPS)
	s.fullscreen = _flag(data.get("fullscreen"), false)
	s.shake = _flag(data.get("shake"), true)
	var wanted: Variant = data.get("text_scale")
	if (wanted is float or wanted is int) and TEXT_SCALES.has(float(wanted)):
		s.text_scale = float(wanted)
	var lang := str(data.get("locale", "fr"))
	s.locale = lang if LOCALES.has(lang) else "fr"
	var saved: Variant = data.get("keys")
	if saved is Dictionary:
		for action: Variant in saved:
			var code := _whole((saved as Dictionary)[action], 0)
			if code > 0:
				s.keys[StringName(str(action))] = code
	return s


static func _whole(value: Variant, fallback: int) -> int:
	return int(value) if value is int or value is float else fallback


static func _flag(value: Variant, fallback: bool) -> bool:
	return value if value is bool else fallback


func to_dict() -> Dictionary:
	var saved := {}
	for action: StringName in keys:
		saved[String(action)] = keys[action]
	return {
		"master": master,
		"music": music,
		"sfx": sfx,
		"fullscreen": fullscreen,
		"shake": shake,
		"text_scale": text_scale,
		"locale": locale,
		"keys": saved,
	}


func volume(which: StringName) -> int:
	return int(get(which))


func nudge_volume(which: StringName, direction: int) -> void:
	set(which, clampi(volume(which) + direction, 0, STEPS))


func cycle_text_scale(direction: int) -> void:
	var i := TEXT_SCALES.find(text_scale) + direction
	text_scale = TEXT_SCALES[posmod(i, TEXT_SCALES.size())]


func cycle_locale(direction: int) -> void:
	locale = LOCALES[posmod(LOCALES.find(locale) + direction, LOCALES.size())]


## Gives `action` the key `code`. If another action was using it, the two
## swap, so no action is ever left without a key. False if nothing was done:
## an action that does not exist, or no key at all.
func rebind(action: StringName, code: int, defaults: Dictionary) -> bool:
	var layout := bindings(defaults)
	if not layout.has(action) or code <= 0:
		return false
	var mine: Array = layout[action]
	for other: StringName in layout:
		var theirs: Array = layout[other]
		if other != action and theirs == [code] and not mine.is_empty():
			keys.erase(other)
			keys[other] = mine[0]
	keys.erase(action)
	keys[action] = code
	return true


## The keys of every action once the player's choices are laid over `defaults`
## (action -> Array of physical keycodes).
func bindings(defaults: Dictionary) -> Dictionary:
	var layout := {}
	for action: StringName in defaults:
		layout[action] = (defaults[action] as Array).duplicate()
	for action: StringName in keys:
		if not layout.has(action):
			continue
		var code: int = keys[action]
		var given_up: Array = layout[action]
		for other: StringName in layout:
			if other != action:
				(layout[other] as Array).erase(code)
		layout[action] = [code]
		for other: StringName in layout:
			if (layout[other] as Array).is_empty():
				layout[other] = _spare(layout, given_up)
	return layout


func _spare(layout: Dictionary, candidates: Array) -> Array:
	for code: int in candidates:
		var free := true
		for action: StringName in layout:
			free = free and not (layout[action] as Array).has(code)
		if free:
			return [code]
	return []
