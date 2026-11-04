extends Node2D

## Violet ring drawn around the player while a shield is active.

const RADIUS := 30.0
const COLOR := Color(0.61, 0.36, 0.9, 0.85)
const WIDTH := 3.0
const SPIN := 2.0


func _process(delta: float) -> void:
	rotation += SPIN * delta


func _draw() -> void:
	for i in 3:
		var start := TAU / 3.0 * i
		draw_arc(Vector2.ZERO, RADIUS, start, start + TAU / 4.0, 16, COLOR, WIDTH, true)
