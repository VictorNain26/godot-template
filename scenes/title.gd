class_name Title
extends Control

## The title screen: the name of the game, a menu (start, options, quit) and
## the keys. Keys, a gamepad and the mouse all work; the look comes from the
## kit's UiStyle, so the game's skin restyles it too. Replace the backdrop
## with the game's own; keep the menu and the legend. It offers MenuContract
## (menu_*), as every menu of the game does.

signal menu_chosen(index: int)

## The scene "Commencer" opens.
const START_SCENE := "res://scenes/main_2d.tscn"
## Baseline of the name of the game.
const LOGO_LINE := 164.0

var menu_dry_run := false
var _index := 0
var _entries: Array[String] = ["Commencer", "Options", "Quitter"]
var _menu: OptionsMenu
var _panel := Rect2()
var _t := 0.0
var _leaving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The menu is drawn, not made of Controls: the screen reads the pointer in
	# _unhandled_input, which a Control that stops the mouse never lets through.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.theme()
	# A browser tab is closed, not quit.
	if OS.has_feature("web"):
		_entries.erase("Quitter")
	_menu = OptionsMenu.new()
	add_child(_menu)
	Prefs.changed.connect(queue_redraw)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _menu.visible or not MenuInput.fresh(event):
		return
	if event is InputEventMouse:
		_pointer(event as InputEventMouse)
	elif MenuInput.pressed(event, MenuInput.DOWN):
		_index = (_index + 1) % _entries.size()
	elif MenuInput.pressed(event, MenuInput.UP):
		_index = posmod(_index - 1, _entries.size())
	elif MenuInput.accepts(event):
		_choose()


## The pointer selects the entry it passes over, and a click chooses it.
func _pointer(event: InputEventMouse) -> void:
	var hit := UiDraw.menu_hit(_panel, _entries.size(), Prefs.px(UiStyle.MENU), event.position)
	if hit < 0:
		return
	_index = hit
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_choose()


func _choose() -> void:
	menu_chosen.emit(_index)
	if menu_dry_run:
		return
	match _entries[_index]:
		"Options":
			_menu.open()
		"Quitter":
			get_tree().quit()
		_:
			_leaving = true
			get_tree().change_scene_to_file(START_SCENE)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiStyle.INK.lerp(UiStyle.EDGE, 0.12))
	if _menu.visible:
		return
	var left := float(UiStyle.MARGIN + UiStyle.UNIT * 2)
	var title := str(ProjectSettings.get_setting("application/config/name")).to_upper()
	UiDraw.logo(self, Vector2(left, LOGO_LINE), title, _t)
	# The keys along the bottom, the menu above them on the right.
	var small := Prefs.px(UiStyle.SMALL)
	var help := Prefs.help()
	var limit := size.x - UiStyle.MARGIN * 2.0 - UiStyle.UNIT * 4.0
	var foot := size.y - UiStyle.MARGIN + UiStyle.UNIT - UiDraw.legend_size(help, small, limit).y
	UiDraw.legend(self, help, Vector2(left, foot), small, limit, UiDraw.LEFT, true)
	var labels: Array = []
	for entry in _entries:
		labels.append(Loc.t(entry))
	var corner := Vector2(size.x - UiStyle.MARGIN, foot - UiStyle.UNIT * 4.0)
	_panel = UiDraw.menu(self, corner, labels, _index, Prefs.px(UiStyle.MENU))


## MenuContract: the entries drawn on the right.
func menu_open() -> void:
	queue_redraw()


func menu_rects() -> Array[Rect2]:
	return UiDraw.menu_rects(_panel, _entries.size(), Prefs.px(UiStyle.MENU))


func menu_index() -> int:
	return _index


func menu_texts() -> Array[String]:
	return _entries.duplicate()


func menu_text_style() -> Dictionary:
	return {"size": UiStyle.MENU, "pairs": UiStyle.row_colours()}
