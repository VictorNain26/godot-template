class_name OwnMenu
extends Control
## A menu the game writes itself, with engine Buttons and no kit_ui, keeping
## MenuContract: MenuInput for keys, pad and stick, the pointer through the
## buttons, its own size and colours.

signal menu_chosen(index: int)

const TEXTS: Array[String] = ["Jouer", "Quitter"]
const SIZE := 24
const INK := Color("1d1b26")
const TEXT := Color("f4efe6")

var menu_dry_run := false
var clicks := 0
var index := 0
var buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var plate := StyleBoxFlat.new()
	plate.bg_color = INK
	var lit := plate.duplicate() as StyleBoxFlat
	lit.border_width_left = 4
	lit.border_color = TEXT
	for i in TEXTS.size():
		var button := Button.new()
		button.text = Loc.t(TEXTS[i])
		button.position = Vector2(100, 100 + i * 80)
		button.size = Vector2(240, 64)
		button.add_theme_font_size_override(&"font_size", Prefs.px(SIZE))
		for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
			button.add_theme_color_override(state, TEXT)
		button.add_theme_stylebox_override(&"normal", plate)
		button.add_theme_stylebox_override(&"hover", lit)
		button.add_theme_stylebox_override(&"pressed", lit)
		button.mouse_entered.connect(func() -> void: index = i)
		button.pressed.connect(func() -> void: _choose(i))
		buttons.append(button)
		add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if not MenuInput.fresh(event):
		return
	if MenuInput.pressed(event, MenuInput.DOWN):
		index = mini(index + 1, TEXTS.size() - 1)
	elif MenuInput.pressed(event, MenuInput.UP):
		index = maxi(index - 1, 0)
	elif MenuInput.accepts(event):
		_choose(index)


func _choose(i: int) -> void:
	index = i
	clicks += 1
	menu_chosen.emit(i)
	if menu_dry_run:
		return
	if TEXTS[i] == "Quitter":
		get_tree().quit()


func menu_open() -> void:
	show()


func menu_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for button in buttons:
		out.append(button.get_global_rect())
	return out


func menu_index() -> int:
	return index


func menu_texts() -> Array[String]:
	return TEXTS.duplicate()


func menu_text_style() -> Dictionary:
	return {"size": SIZE, "pairs": [[TEXT, INK]]}
