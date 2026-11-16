class_name MenuInput
extends RefCounted

## What a key, a button or a stick means in a menu, so that a keyboard and a
## gamepad both get through every one of them. It reads events and decides
## nothing: each menu keeps its own rows and what they do.

const UP: Array[StringName] = [&"ui_up", &"move_up"]
const DOWN: Array[StringName] = [&"ui_down", &"move_down"]
const ACCEPT: Array[StringName] = [&"ui_accept", &"interact"]
## A stick counts as tilted past PRESS and as back at rest under REST.
const PRESS := 0.5
const REST := 0.3

## [device, axis] -> the side (-1, 0, 1) the stick was last seen leaning to.
static var _tilt := {}


## True if the event presses one of the actions. An action the game does not
## have is skipped: the two games share their menus, not their actions.
static func pressed(event: InputEvent, actions: Array[StringName]) -> bool:
	for action in actions:
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false


## The engine's accept keys, the game's own, and the bottom face button of a
## gamepad whatever the game binds to it.
static func accepts(event: InputEvent) -> bool:
	var button := event as InputEventJoypadButton
	if button != null:
		return button.pressed and button.button_index == JOY_BUTTON_A
	return pressed(event, ACCEPT)


## False for a stick movement that only continues a tilt already counted. A
## stick sends an event for every small change, and each one past the dead
## zone reads as a press: without this, one push moves several rows.
## A menu asks once per event, before looking at what the event means.
static func fresh(event: InputEvent) -> bool:
	var motion := event as InputEventJoypadMotion
	if motion == null:
		return true
	var key := Vector2i(motion.device, motion.axis)
	var was: int = _tilt.get(key, 0)
	var side := was
	var value := motion.axis_value
	if absf(value) >= PRESS:
		side = int(signf(value))
	elif absf(value) < REST or int(signf(value)) != was:
		side = 0
	_tilt[key] = side
	return side != 0 and side != was
