class_name OptionsMenu
extends Control

## Options and key bindings, shared by the pause menu and the title screen.
## While it is open it takes every key and button.

signal closed

const MAIN: Array[StringName] = [
	&"master", &"music", &"sfx", &"fullscreen", &"shake", &"text", &"locale", &"keys", &"back"
]
const NAMES := {
	&"master": "Volume général",
	&"music": "Musique",
	&"sfx": "Effets sonores",
	&"fullscreen": "Plein écran",
	&"shake": "Secousses d'écran",
	&"text": "Taille du texte",
	&"locale": "Langue",
	&"keys": "Touches",
	&"reset": "Rétablir les touches",
	&"back": "Retour",
}
## Width of the panel before the player's text scale.
const WIDTH := 640

var on_keys := false
var listening := false
var index := 0
var _heading: Label
var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _legend: LegendBar
var _rows: Array[MenuRow] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiStyle.theme()
	visible = false
	# The screen behind stays faintly visible: the options are a page laid
	# over the title or the pause, not another place.
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.INK, UiStyle.PAGE_ALPHA)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	# A CenterContainer keeps the panel centred whatever its length or type size.
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	_panel = PanelContainer.new()
	centre.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", UiStyle.UNIT * 2)
	_panel.add_child(box)
	_heading = Label.new()
	_heading.add_theme_color_override(&"font_color", UiStyle.ACCENT)
	box.add_child(_heading)
	# The list scrolls when a large type or a long list outgrows the screen.
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override(&"separation", UiStyle.UNIT / 2)
	_scroll.add_child(_list)
	_legend = LegendBar.new()
	box.add_child(_legend)
	Prefs.changed.connect(refresh)


func open() -> void:
	visible = true
	on_keys = false
	listening = false
	index = 0
	refresh()


func rows() -> Array[StringName]:
	if not on_keys:
		return MAIN
	var list: Array[StringName] = []
	for action: StringName in Prefs.actions:
		list.append(action)
	list.append(&"reset")
	list.append(&"back")
	return list


## A row as one line of text: what the screen shows in two columns.
func row_text(row: StringName) -> String:
	var value := row_value(row)
	return row_label(row) if value.is_empty() else Loc.t("%s : %s") % [row_label(row), value]


func row_label(row: StringName) -> String:
	return Loc.t(Prefs.actions[row]) if Prefs.actions.has(row) else Loc.t(NAMES[row])


## The value a row holds, empty for a row that only does something.
func row_value(row: StringName) -> String:
	var s := Prefs.settings
	var value := ""
	if Prefs.actions.has(row):
		var waiting := listening and row == rows()[index]
		value = Loc.t("Appuie sur une touche") if waiting else Prefs.key_label(row, true)
	elif Settings.VOLUMES.has(row):
		value = str(s.volume(row))
	elif row == &"fullscreen":
		value = _yes_no(s.fullscreen)
	elif row == &"shake":
		value = _yes_no(s.shake)
	elif row == &"text":
		value = Loc.t("%d %%") % int(round(s.text_scale * 100.0))
	elif row == &"locale":
		value = Settings.LOCALE_NAMES[s.locale]
	return value


func move(direction: int) -> void:
	index = posmod(index + direction, rows().size())
	refresh()


## Left and right change a value; accept toggles it or goes in.
func change(direction: int) -> void:
	var s := Prefs.settings
	var row := rows()[index]
	match row:
		&"master", &"music", &"sfx":
			s.nudge_volume(row, direction)
		&"fullscreen":
			s.fullscreen = not s.fullscreen
		&"shake":
			s.shake = not s.shake
		&"text":
			s.cycle_text_scale(direction)
		&"locale":
			s.cycle_locale(direction)
		_:
			return
	Prefs.commit()


func accept() -> void:
	var row := rows()[index]
	if Prefs.actions.has(row):
		listening = true
		refresh()
	elif row == &"keys":
		on_keys = true
		index = 0
		refresh()
	elif row == &"reset":
		Prefs.reset_keys()
	elif row == &"back":
		back()
	else:
		change(1)


func back() -> void:
	if on_keys:
		on_keys = false
		index = MAIN.find(&"keys")
		refresh()
	else:
		visible = false
		closed.emit()


## The next key pressed becomes the key of the selected action.
func take_key(code: Key) -> void:
	listening = false
	Prefs.rebind(rows()[index], code)
	refresh()


func refresh() -> void:
	if not visible:
		return
	var list := rows()
	while _rows.size() < list.size():
		var row := MenuRow.new()
		row.pointed.connect(_point.bind(_rows.size()))
		row.clicked.connect(_click.bind(_rows.size()))
		_list.add_child(row)
		_rows.append(row)
	var heading := Prefs.px(UiStyle.HEADING)
	_heading.text = Loc.t("TOUCHES") if on_keys else Loc.t("OPTIONS")
	_heading.add_theme_font_override(&"font", UiStyle.display(heading))
	_heading.add_theme_font_size_override(&"font_size", heading)
	for i in _rows.size():
		var row := _rows[i]
		row.visible = i < list.size()
		if not row.visible:
			continue
		row.level = Prefs.settings.volume(list[i]) if Settings.VOLUMES.has(list[i]) else 0
		row.steps = Settings.STEPS
		row.show_row(row_label(list[i]), i == index, _kind(list[i]), row_value(list[i]))
	_legend.show_entries(_keys_legend())
	_fit.call_deferred()


## Sizes the panel for the text scale and keeps the selected row in view.
func _fit() -> void:
	var screen := get_viewport_rect().size
	var wide := minf(Prefs.px(WIDTH), screen.x - UiStyle.MARGIN * 2.0)
	_legend.limit = wide
	_legend.update_minimum_size()
	var around := _heading.get_minimum_size().y + _legend.get_minimum_size().y
	var room := screen.y - UiStyle.MARGIN * 2.0 - around - UiStyle.UNIT * 10.0
	# Whole rows only: a row cut in half reads as a fault, not as "more below".
	var pitch := _rows[0].get_minimum_size().y + _list.get_theme_constant(&"separation")
	room = floorf(room / pitch) * pitch
	_scroll.custom_minimum_size = Vector2(wide, minf(_list.get_minimum_size().y, room))
	if index < _rows.size():
		_scroll.ensure_control_visible.call_deferred(_rows[index])


func _kind(row: StringName) -> MenuRow.Kind:
	if Prefs.actions.has(row):
		var waiting := listening and row == rows()[index]
		return MenuRow.Kind.NOTE if waiting else MenuRow.Kind.KEY
	if Settings.VOLUMES.has(row):
		return MenuRow.Kind.SLIDER
	if row == &"keys":
		return MenuRow.Kind.PAGE
	return MenuRow.Kind.PLAIN if row_value(row).is_empty() else MenuRow.Kind.VALUE


## What the keys do on this page, shown under the list.
func _keys_legend() -> Array:
	var cancel := Prefs.cancel_label()
	if listening:
		return [[Loc.t("Annuler"), [cancel]]]
	var keys := [
		[Loc.t("Valider"), [Prefs.accept_label()]],
		[Loc.t("Retour"), [cancel]],
	]
	if not on_keys:
		keys.push_front([Loc.t("Régler"), ["<", ">"]])
	return keys


func _input(event: InputEvent) -> void:
	if not visible or event is InputEventMouse:
		return
	get_viewport().set_input_as_handled()
	if not MenuInput.fresh(event):
		return
	if listening:
		var key := event as InputEventKey
		if key != null and key.pressed and not key.echo:
			take_key(key.physical_keycode)
		elif event is InputEventJoypadButton and event.is_pressed():
			# Only keys are rebound: a gamepad button gives up, or it could never leave.
			listening = false
			refresh()
	elif MenuInput.pressed(event, MenuInput.BACK):
		back()
	elif MenuInput.pressed(event, MenuInput.UP):
		move(-1)
	elif MenuInput.pressed(event, MenuInput.DOWN):
		move(1)
	elif MenuInput.pressed(event, MenuInput.LEFT):
		change(-1)
	elif MenuInput.pressed(event, MenuInput.RIGHT):
		change(1)
	elif MenuInput.accepts(event):
		accept()


## The pointer selects the row it passes over.
func _point(i: int) -> void:
	if listening or i == index or i >= rows().size():
		return
	index = i
	refresh()


## A click uses the row: it turns a value one way or the other, and does
## what accepting does on any other row. While a key is awaited, it gives up.
func _click(direction: int, i: int) -> void:
	if listening:
		listening = false
		refresh()
		return
	if i >= rows().size():
		return
	index = i
	var kind := _kind(rows()[i])
	if kind == MenuRow.Kind.VALUE or kind == MenuRow.Kind.SLIDER:
		change(direction)
	else:
		accept()
	refresh()


func _yes_no(value: bool) -> String:
	return Loc.t("Oui") if value else Loc.t("Non")
