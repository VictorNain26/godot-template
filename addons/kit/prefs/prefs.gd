extends Node
## Autoload "Prefs": applies the player's options to the engine and keeps them
## in their own file, so starting a new game never resets them. Part of the
## kit (addons/kit).
##
## What belongs to the game comes from its kit config, a script named by the
## project setting kit/config (res://kit_config.gd by default):
##   ACTIONS        the actions the player may rebind, with the name the menu shows
##   FIXED_ACTIONS  actions not offered for rebinding (pause), kept off taken keys
##   HELP           the legend of the title and pause screens: [label, [actions]]
##   static func skin()  optional: sets UiStyle's tokens to give the menus a look

signal changed

const PATH := "user://settings.json"
const CONFIG_SETTING := "kit/config"
const DEFAULT_CONFIG := "res://kit_config.gd"
const BUSES := {&"master": &"Master", &"music": &"Music", &"sfx": &"Sfx"}
const CANCEL_KEY := KEY_ESCAPE
## The engine names keys in English; these are the ones a French player meets.
const FRENCH_KEYS := {
	"Space": "Espace",
	"Shift": "Maj",
	"Escape": "Échap",
	"Enter": "Entrée",
	"Up": "Haut",
	"Down": "Bas",
	"Left": "Gauche",
	"Right": "Droite",
	"Backspace": "Retour arrière",
}
## Gamepad buttons as the legends name them: the Xbox layout, which most
## pads copy. The pad of the direction buttons is drawn as arrows.
const PAD_NAMES := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "^",
	JOY_BUTTON_DPAD_DOWN: "v",
	JOY_BUTTON_DPAD_LEFT: "<",
	JOY_BUTTON_DPAD_RIGHT: ">",
}

## From the kit config: see the header.
var actions := {}
var fixed_actions: Array[StringName] = []
var help_entries: Array = []

var settings := Settings.new()
## Off in tests, in recordings and without a window: the player's file is
## then neither read nor written. A test that wants the file sets `path` to a
## scratch file and turns this back on.
var persist := true
var path := PATH
## True while the player's last press came from a gamepad: the legends then
## name its buttons instead of keys.
var pad := false
var _defaults := {}
var _labels := {}


func _init() -> void:
	load_config()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action: StringName in actions:
		_defaults[action] = _keys_of(action)
	for action: StringName in fixed_actions:
		_defaults[action] = _keys_of(action)
	# Seen at the window, before any menu marks the event as handled.
	get_tree().root.window_input.connect(notice)
	persist = not _headless() and not Settings.is_test_run(OS.get_cmdline_args())
	if persist and not load_from(path):
		settings.locale = Settings.pick_locale(OS.get_locale_language())
	apply()
	# An exported build checks itself with `-- --selftest` (mise run export-smoke).
	if OS.get_cmdline_user_args().has("--selftest"):
		add_child((load("res://addons/kit/dev/self_test.gd") as GDScript).new())


## Reads the game's kit config and applies its skin. A game without one gets
## no rebindable action and the kit's own look.
func load_config() -> void:
	var path := str(ProjectSettings.get_setting(CONFIG_SETTING, DEFAULT_CONFIG))
	if not ResourceLoader.exists(path):
		return
	var config := load(path) as GDScript
	if config == null:
		return
	var constants := config.get_script_constant_map()
	var found: Variant = constants.get("ACTIONS", {})
	actions = (found as Dictionary).duplicate() if found is Dictionary else {}
	fixed_actions.clear()
	found = constants.get("FIXED_ACTIONS", [])
	if found is Array:
		for action: Variant in found as Array:
			fixed_actions.append(StringName(str(action)))
	found = constants.get("HELP", [])
	help_entries = (found as Array).duplicate() if found is Array else []
	if config.has_method(&"skin"):
		config.call(&"skin")
		UiStyle.reset()


func px(size: float) -> int:
	return int(round(size * settings.text_scale))


## Follows the device the player is using. A key or a click returns the
## legends to the keyboard; a button or a stick pushed past a press, to the pad.
func notice(event: InputEvent) -> void:
	var now := pad
	if event is InputEventJoypadButton and event.is_pressed():
		now = true
	elif event is InputEventJoypadMotion:
		now = now or absf((event as InputEventJoypadMotion).axis_value) >= MenuInput.PRESS
	elif (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		now = false
	if now != pad:
		pad = now
		changed.emit()


## The button or key to show for an action: the gamepad's while the player
## uses one, otherwise the key as printed on their own keyboard. `keyboard`
## asks for the key whatever the device, as the page of keys does.
func key_label(action: StringName, keyboard: bool = false) -> String:
	if pad and not keyboard:
		var button := pad_button(action)
		if button != "":
			return button
	var codes: Array = settings.bindings(_defaults).get(action, [])
	if codes.is_empty():
		return "?"
	return key_name(codes[0])


## The gamepad button bound to an action, or "" if it has none.
func pad_button(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null and PAD_NAMES.has(button.button_index):
			return PAD_NAMES[button.button_index]
	return ""


## What validates a menu choice, and what goes back: Enter and Escape on a
## keyboard, the bottom and right face buttons on a pad (see MenuInput).
func accept_label() -> String:
	return PAD_NAMES[JOY_BUTTON_A] if pad else key_name(KEY_ENTER)


func cancel_label() -> String:
	return PAD_NAMES[JOY_BUTTON_B] if pad else key_name(CANCEL_KEY)


## The name of a key in the player's language, as their keyboard prints it.
func key_name(code: Key) -> String:
	if not _labels.has(code):
		_labels[code] = OS.get_keycode_string(_printed(code))
	var label: String = _labels[code]
	return FRENCH_KEYS.get(label, label) if settings.locale == "fr" else label


## What the main keys do, as [label, [key names]] pairs: the legend of the
## title and pause screens.
func help() -> Array:
	var out: Array = []
	for entry: Array in help_entries:
		var names: Array[String] = []
		for action: StringName in entry[1]:
			names.append(key_label(action))
		out.append([Loc.t(entry[0]), names])
	return out


## The same legend as one line of text.
func help_line() -> String:
	var parts: PackedStringArray = []
	for entry: Array in help():
		parts.append(Loc.t("%s : %s") % [entry[0], " ".join(entry[1])])
	return "     ".join(parts)


## Key names by action, to fill {jump}-style marks in a text.
func key_names() -> Dictionary:
	var names := {}
	for action: StringName in actions:
		names[String(action)] = key_label(action)
	return names


func default_keys() -> Dictionary:
	return _defaults


## Applies the options and, outside tests, writes them to disk.
func commit() -> void:
	apply()
	if persist:
		save_to(path)
	changed.emit()


func rebind(action: StringName, code: Key) -> bool:
	if code == CANCEL_KEY or not actions.has(action):
		return false
	if not settings.rebind(action, code, _defaults):
		return false
	commit()
	return true


func reset_keys() -> void:
	settings.keys.clear()
	commit()


func apply() -> void:
	for which: StringName in BUSES:
		var bus := AudioServer.get_bus_index(BUSES[which])
		if bus >= 0:
			AudioServer.set_bus_volume_db(bus, Settings.volume_db(settings.volume(which)))
			AudioServer.set_bus_mute(bus, settings.volume(which) == 0)
	TranslationServer.set_locale(settings.locale)
	var layout := settings.bindings(_defaults)
	for action: StringName in layout:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		for code: Key in layout[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)
	if not _headless():
		var mode := DisplayServer.window_get_mode()
		var wanted := window_mode_for(mode, settings.fullscreen)
		if wanted != mode:
			DisplayServer.window_set_mode(wanted)


## The window mode the fullscreen option asks for, given the current one.
## Only fullscreen is ours to change: a window the player maximised stays
## maximised when a volume moves, and is not asked for again on every option.
func window_mode_for(
	current: DisplayServer.WindowMode, fullscreen: bool
) -> DisplayServer.WindowMode:
	var full := (
		current == DisplayServer.WINDOW_MODE_FULLSCREEN
		or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	if full == fullscreen:
		return current
	if fullscreen:
		return DisplayServer.WINDOW_MODE_FULLSCREEN
	return DisplayServer.WINDOW_MODE_WINDOWED


func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return false
	settings = Settings.from_dict(data)
	return true


func save_to(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings.to_dict(), "\t"))


func _keys_of(action: StringName) -> Array:
	var codes: Array = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			codes.append((event as InputEventKey).physical_keycode)
	return codes


## A physical key as the keyboard layout names it (A is Q on an AZERTY board).
## The headless and web display servers cannot tell: they keep the position's name.
func _printed(code: Key) -> Key:
	if _headless() or OS.has_feature("web"):
		return code
	var label := DisplayServer.keyboard_get_label_from_physical(code)
	return label if label != KEY_NONE else code


func _headless() -> bool:
	return DisplayServer.get_name() == "headless"
