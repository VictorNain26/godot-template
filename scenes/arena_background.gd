extends Node2D

## Draws the arena floor: dark fill, faint grid and a glowing border.

const ARENA := Rect2(0, 0, 1152, 648)
const FILL := Color(0.06, 0.06, 0.13)
const GRID := Color(0.16, 0.18, 0.32)
const BORDER := Color(0.3, 0.79, 0.94, 0.6)
const CELL := 48.0


func _draw() -> void:
	draw_rect(ARENA, FILL)
	var x := CELL
	while x < ARENA.end.x:
		draw_line(Vector2(x, 0), Vector2(x, ARENA.end.y), GRID, 1.0)
		x += CELL
	var y := CELL
	while y < ARENA.end.y:
		draw_line(Vector2(0, y), Vector2(ARENA.end.x, y), GRID, 1.0)
		y += CELL
	draw_rect(ARENA.grow(-2), BORDER, false, 4.0)
