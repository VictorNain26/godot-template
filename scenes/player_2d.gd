class_name Player2D
extends CharacterBody2D

## Thin node script: reads input, delegates movement to PlayerMotion and the
## arena bounds to Arena.

@export var speed: float = 200.0
@export var arena: Rect2 = Rect2(0, 0, 1152, 648)
@export var half_extent: float = 16.0


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_and_collide(PlayerMotion.displacement(input, speed, delta))
	position = Arena.clamp_point(position, arena, half_extent)
