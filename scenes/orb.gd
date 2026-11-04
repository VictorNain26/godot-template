class_name Orb
extends Area2D

## Collectible: emits `collected` once when the player touches it; draws a
## pulsing gold core with a soft halo.

signal collected(orb: Orb)

const RADIUS := 12.0
const CORE := Color(1.0, 0.82, 0.4)
const HALO := Color(1.0, 0.82, 0.4, 0.18)
const PULSE_SPEED := 5.0
const PULSE_AMOUNT := 0.15

var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + PULSE_AMOUNT * sin(_time * PULSE_SPEED)
	draw_circle(Vector2.ZERO, RADIUS * 2.2 * pulse, HALO)
	draw_circle(Vector2.ZERO, RADIUS * pulse, CORE)
	draw_circle(Vector2(-3, -3), RADIUS * 0.35, Color(1, 1, 1, 0.8))


func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		set_deferred("monitoring", false)
		collected.emit(self)
