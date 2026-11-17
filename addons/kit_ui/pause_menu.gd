class_name PauseMenu
extends CanvasLayer

## Pause overlay. Runs while the tree is paused. Part of the kit's menus (addons/kit_ui).
##
## `entries` are [id, label] pairs: "resume" resumes, "options" opens the
## options page, and any other id is handed to the game through `chosen`:
## the menu hides and play stays paused, so nothing moves during the game's
## own transition; the game unpauses when it is ready.
## `blocked`, when set, is asked before any key reaches the menu: while it
## answers true (a scene change, say), the pause key neither opens nor
## closes it. `moved` lets the game play a sound when the selection
## moves; the kit itself makes none.

signal chosen(id: StringName)
signal moved

## Width of the panel before the player's text scale.
const WIDTH := 360

var entries: Array = [[&"resume", "Reprendre"], [&"options", "Options"], [&"title", "Écran titre"]]
var blocked := Callable()
var options: OptionsMenu
var _root: Control
var _index := 0
var _heading: Label
var _help: LegendBar
var _rows: Array[MenuRow] = []
var _resuming := false


func _init(choices: Array = []) -> void:
	if not choices.is_empty():
		entries = choices


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_root.theme = UiStyle.theme()
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.INK, UiStyle.VEIL_ALPHA)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiStyle.UNIT * 3)
	centre.add_child(column)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", floori(UiStyle.UNIT / 2.0))
	panel.add_child(box)
	_heading = Label.new()
	_heading.add_theme_color_override(&"font_color", UiStyle.ACCENT)
	box.add_child(_heading)
	var gap := Control.new()
	gap.custom_minimum_size.y = UiStyle.UNIT
	box.add_child(gap)
	for i in entries.size():
		var row := MenuRow.new()
		row.pointed.connect(_point.bind(i))
		row.clicked.connect(_click.bind(i))
		box.add_child(row)
		_rows.append(row)
	# The keys, under the panel, on a plate of their own.
	_help = LegendBar.new()
	_help.plated = true
	column.add_child(_help)
	options = OptionsMenu.new()
	_root.add_child(options)
	Prefs.changed.connect(_refresh)
	_refresh()


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if options.visible or _resuming or not MenuInput.fresh(event):
		return
	# During the game's own transition, even the pause key waits.
	var waiting: bool = blocked.is_valid() and blocked.call()
	if waiting:
		return
	if event.is_action_pressed(&"pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif get_tree().paused and _root.visible:
		if MenuInput.pressed(event, MenuInput.DOWN):
			_index = (_index + 1) % entries.size()
			moved.emit()
		elif MenuInput.pressed(event, MenuInput.UP):
			_index = (_index + entries.size() - 1) % entries.size()
			moved.emit()
		elif MenuInput.accepts(event):
			_choose()
		_refresh()
		get_viewport().set_input_as_handled()


func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_root.visible = value
	_index = 0
	_refresh()


## Play resumes two physics ticks after the choice: by then the press that
## chose is no longer "just pressed", and the game does not act on it too.
func _resume() -> void:
	_resuming = true
	_root.visible = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	_resuming = false
	_set_paused(false)


## The pointer selects the entry it passes over, and a click chooses it.
func _point(i: int) -> void:
	if _resuming or options.visible or i == _index:
		return
	_index = i
	moved.emit()
	_refresh()


func _click(_direction: int, i: int) -> void:
	if _resuming or options.visible:
		return
	_index = i
	_refresh()
	_choose()


func _choose() -> void:
	var picked: Array = entries[_index]
	var id := StringName(str(picked[0]))
	match id:
		&"resume":
			# Not awaited: _resuming keeps further input out until it ends.
			@warning_ignore("missing_await")
			_resume()
		&"options":
			options.open()
		_:
			_root.visible = false
			chosen.emit(id)


func _refresh() -> void:
	var heading := Prefs.px(UiStyle.HEADING)
	_heading.text = Loc.t("PAUSE")
	_heading.add_theme_font_override(&"font", UiStyle.display(heading))
	_heading.add_theme_font_size_override(&"font_size", heading)
	_help.show_entries(legend())
	var px := Prefs.px(UiStyle.MENU)
	var strong := UiStyle.body(UiStyle.STRONG)
	var wide := float(Prefs.px(WIDTH))
	for i in _rows.size():
		var entry: Array = entries[i]
		var label := Loc.t(str(entry[1]))
		_rows[i].show_row(label, i == _index)
		var needed := strong.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		wide = maxf(wide, needed + UiStyle.UNIT * 6.0)
	# Wide enough for the longest entry at this text size.
	_rows[0].custom_minimum_size.x = wide


## What the keys do while the game is paused, shown under the panel: the
## menu's own keys, not the game's, and the pause key as the way back.
func legend() -> Array:
	return [
		[Loc.t("Choisir"), ["^", "v"]],
		[Loc.t("Valider"), [Prefs.accept_label()]],
		[Loc.t("Reprendre"), [Prefs.key_label(&"pause")]],
	]
