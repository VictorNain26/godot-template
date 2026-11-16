class_name KitSim
extends RefCounted

## Real input for tests: keys, gamepad buttons, a stick, the pointer, sent the
## way the engine sends them. Part of the kit (addons/kit).
##
## Without a window the engine gives the mouse to no Control: a test that
## clicks a menu emits its rows' signals instead, and a scene run under Xvfb
## sends real clicks (see the kit's README).


## A key event as a keyboard sends it: by what the key means and by where it is.
static func key(code: Key, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event


static func pad(button: JoyButton, pressed: bool = true, device: int = 0) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	event.device = device
	return event


static func stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


## The pointer moved to `at`, in the coordinates of the window.
static func point(at: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	return event


## A mouse button at `at`, pressed or let go.
static func click(
	at: Vector2, pressed: bool = true, button: MouseButton = MOUSE_BUTTON_LEFT
) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = button
	event.pressed = pressed
	return event


## Sends an event the way the engine does: the Input singleton learns of it,
## then the nodes. Without the flush a headless run keeps it in a buffer.
static func send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## A key or a button pressed and let go.
static func tap(event: InputEvent) -> void:
	send(event)
	var up := event.duplicate() as InputEvent
	up.set(&"pressed", false)
	send(up)


## Lets go of every key, button and stick a test may have left down.
static func release_all() -> void:
	for code: Key in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE, KEY_E, KEY_UP, KEY_DOWN]:
		send(key(code, false))
	for axis: JoyAxis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		send(stick(axis, 0.0))


## Waits `count` frames.
static func frames(tree: SceneTree, count: int) -> void:
	for i in count:
		await tree.process_frame
