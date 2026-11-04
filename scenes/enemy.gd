class_name Enemy
extends Area2D

## Patrolling hazard: follows Patrol between point_a and point_b, spins, and
## emits `touched_player` on contact.

signal touched_player

const SIZE := 18.0
const FILL := Color(0.97, 0.15, 0.52)
const GLOW := Color(0.97, 0.15, 0.52, 0.2)
const SPIN := 3.0

@export var point_a: Vector2
@export var point_b: Vector2
@export var speed: float = 140.0

var _elapsed := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	reset()


func reset() -> void:
	_elapsed = 0.0
	position = Patrol.position_at(point_a, point_b, speed, _elapsed)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	position = Patrol.position_at(point_a, point_b, speed, _elapsed)
	rotation += SPIN * delta


func _draw() -> void:
	draw_circle(Vector2.ZERO, SIZE * 1.8, GLOW)
	var diamond := PackedVector2Array(
		[Vector2(0, -SIZE), Vector2(SIZE, 0), Vector2(0, SIZE), Vector2(-SIZE, 0)]
	)
	draw_colored_polygon(diamond, FILL)


func _on_body_entered(body: Node2D) -> void:
	if body is Player2D:
		touched_player.emit()
