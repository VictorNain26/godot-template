class_name RoundState
extends RefCounted

## One timed round: time counts down, orbs add points, a hit or time-out ends it.

var score: int = 0
var time_left: float
var over: bool = false


func _init(duration: float) -> void:
	time_left = duration


func tick(delta: float) -> void:
	if over:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		over = true


func collect() -> void:
	if not over:
		score += 1


func hit() -> void:
	over = true
