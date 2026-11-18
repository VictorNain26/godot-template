class_name MenuRow
extends Control

## One line of a menu: a label on the left and, on the right, nothing, a
## value, a slider, a key cap or the mark of a sub-page. Being selected lights
## a plate behind the row and never moves what is written on it. The pointer
## selects a row by passing over it and uses it with a click: on the left
## half of a value, the click lowers it, anywhere else it raises it.
## Part of the kit's menus (addons/kit_ui), shared by every game built on the template.

## The pointer came over the row.
signal pointed
## A left click on the row: -1 on the left half of an adjustable value, 1
## anywhere else.
signal clicked(direction: int)

## VALUE and SLIDER change with left and right; NOTE is a text that does not.
enum Kind { PLAIN, VALUE, SLIDER, KEY, PAGE, NOTE }

var label := ""
var value := ""
var kind := Kind.PLAIN
var level := 0
var steps := 10
var focused := false
## Left and right change the value: arrows say so while the row is selected.
var adjustable := false
## Where the value was last drawn, left and right edges, for the pointer.
var value_span := Vector2.ZERO


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Passes what it does not take, so the wheel still scrolls the list.
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(pointed.emit)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(side(button.position.x))
		accept_event()


## Which way a click at `x` turns the value: -1 on the left half of an
## adjustable value and its left arrow, 1 anywhere else.
func side(x: float) -> int:
	if not adjustable:
		return 1
	var arrow := Prefs.px(UiStyle.MENU) * 1.4
	var middle := (value_span.x + value_span.y) * 0.5
	return -1 if x >= value_span.x - arrow and x < middle else 1


## Sets what the row shows and asks for a redraw.
func show_row(text: String, selected: bool, shown: Kind = Kind.PLAIN, right: String = "") -> void:
	label = text
	focused = selected
	kind = shown
	value = right
	adjustable = shown == Kind.VALUE or shown == Kind.SLIDER
	update_minimum_size()
	queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(0.0, Prefs.px(UiStyle.MENU) + UiStyle.ROW_PAD * 2.0)


func _draw() -> void:
	var px := Prefs.px(UiStyle.MENU)
	var rect := Rect2(Vector2.ZERO, size)
	UiDraw.row(self, rect, label, focused, px)
	var colour := UiStyle.ACCENT_HOT if focused else UiStyle.TEXT
	var gutter := roundf(px * 0.9)
	var right := size.x - UiStyle.UNIT * 2 - gutter
	var middle := size.y * 0.5
	var left := right
	var font := UiStyle.body(UiStyle.STRONG if focused else UiStyle.REGULAR)
	var line := UiDraw.baseline(font, px, rect)
	match kind:
		Kind.VALUE, Kind.NOTE:
			left -= UiDraw.text(self, font, Vector2(right, line), value, px, colour, UiDraw.RIGHT)
		Kind.SLIDER:
			var bar := Vector2(roundf(px * 0.5) * steps + 4.0 * (steps - 1), roundf(px * 0.7))
			left -= bar.x
			UiDraw.slider(
				self, Rect2(Vector2(left, middle - bar.y * 0.5), bar), level, steps, colour
			)
		Kind.KEY:
			left -= UiDraw.keycap_width(value, px)
			UiDraw.keycap(self, Vector2(left, line), value, px, colour)
		Kind.PAGE:
			var at := Vector2(right + gutter * 0.5, middle)
			UiDraw.chevron(self, at, px * 0.28, Vector2.RIGHT, colour)
	value_span = Vector2(left, right)
	if focused and adjustable:
		var half := px * 0.28
		UiDraw.chevron(self, Vector2(right + gutter * 0.5, middle), half, Vector2.RIGHT, colour)
		UiDraw.chevron(self, Vector2(left - gutter * 0.5, middle), half, Vector2.LEFT, colour)
