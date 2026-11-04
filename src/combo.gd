class_name Combo
extends RefCounted

## Chain multiplier: each collect within `window` seconds of the previous one
## raises it by one, up to MAX; a longer gap starts over at x1.

const MAX := 5

var _window: float
var _last := -INF
var _multiplier := 0


func _init(window: float) -> void:
	_window = window


func register(time: float) -> int:
	if time - _last <= _window:
		_multiplier = mini(_multiplier + 1, MAX)
	else:
		_multiplier = 1
	_last = time
	return _multiplier
