class_name LegendBar
extends Control

## A line of key caps with what each key does, as a node a container can
## place. `entries` are [label, [keys]] pairs; see UiDraw.legend.
## Part of the kit (addons/kit), shared by every game built on the template.

var entries: Array = []
## Widest the legend may be before it wraps to a second line.
var limit := 1280.0 - 2.0 * UiStyle.MARGIN
## A plate behind the legend, for when it lies over the game.
var plated := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_entries(list: Array) -> void:
	entries = list
	update_minimum_size()
	queue_redraw()


func _pad() -> Vector2:
	return Vector2(UiStyle.UNIT * 2, UiStyle.UNIT) if plated else Vector2.ZERO


func _get_minimum_size() -> Vector2:
	var px := Prefs.px(UiStyle.SMALL)
	return UiDraw.legend_size(entries, px, limit - _pad().x * 2.0) + _pad() * 2.0


func _draw() -> void:
	var px := Prefs.px(UiStyle.SMALL)
	var wide := limit - _pad().x * 2.0
	UiDraw.legend(self, entries, Vector2(size.x * 0.5, _pad().y), px, wide, UiDraw.CENTER, plated)
