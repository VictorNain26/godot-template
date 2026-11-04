class_name RoundState
extends RefCounted

## One timed round: time counts down, orbs add points, a hit ends it unless a
## shield absorbs it.

var score: int = 0
var time_left: float
var over: bool = false
var shield: bool = false


func _init(duration: float) -> void:
	time_left = duration


func tick(delta: float) -> void:
	if over:
		return
	time_left = maxf(time_left - delta, 0.0)
	if time_left == 0.0:
		over = true


func collect(points: int = 1) -> void:
	if not over:
		score += points


func add_time(seconds: float) -> void:
	if not over:
		time_left += seconds


func hit() -> void:
	if shield:
		shield = false
		return
	over = true
