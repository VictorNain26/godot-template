class_name Orb
extends Area2D

## Collectible: emits `collected` once when the player touches it; draws a
## pulsing core with a soft halo, coloured by its power-up kind.

signal collected(orb: Orb)

const RADIUS := 12.0
const COLORS := {
	PowerUps.Kind.NONE: Color(1.0, 0.82, 0.4),
	PowerUps.Kind.TIME: Color(0.02, 0.84, 0.63),
	PowerUps.Kind.SHIELD: Color(0.61, 0.36, 0.9),
}
const HALO_ALPHA := 0.18
const PULSE_SPEED := 5.0
const PULSE_AMOUNT := 0.15

var kind: PowerUps.Kind = PowerUps.Kind.NONE
var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + PULSE_AMOUNT * sin(_time * PULSE_SPEED)
	var core: Color = COLORS[kind]
	draw_circle(Vector2.ZERO, RADIUS * 2.2 * pulse, Color(core, HALO_ALPHA))
	draw_circle(Vector2.ZERO, RADIUS * pulse, core)
	draw_circle(Vector2(-3, -3), RADIUS * 0.35, Color(1, 1, 1, 0.8))


func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		set_deferred("monitoring", false)
		collected.emit(self)
