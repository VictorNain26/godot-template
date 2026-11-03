class_name Player3D
extends CharacterBody3D

## Thin node script: reads input, delegates the movement rule to PlayerMotion.

@export var speed: float = 5.0


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move_and_collide(PlayerMotion.ground_displacement(input, speed, delta))
