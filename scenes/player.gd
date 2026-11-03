extends CharacterBody2D

## Thin node script: reads input, delegates the movement rule to PlayerMotion.

@export var speed: float = 200.0


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move_and_collide(PlayerMotion.displacement(input, speed, delta))
