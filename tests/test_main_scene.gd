extends GutTest

const MAIN_SCENE := "res://scenes/main.tscn"
const DELTA := 0.5

var _player: CharacterBody2D


func before_each() -> void:
	var main: Node = add_child_autofree(load(MAIN_SCENE).instantiate())
	_player = main.get_node("Player") as CharacterBody2D


func after_each() -> void:
	for action: String in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		Input.action_release(action)


func test_main_scene_has_player_body() -> void:
	assert_not_null(_player, "Main must have a CharacterBody2D named Player")


func test_right_input_moves_player_right() -> void:
	var start := _player.position
	Input.action_press("ui_right")
	_player._physics_process(DELTA)
	assert_eq(_player.position - start, Vector2(_player.speed * DELTA, 0.0))


func test_no_input_keeps_player_still() -> void:
	var start := _player.position
	_player._physics_process(DELTA)
	assert_eq(_player.position, start)


func test_diagonal_input_moves_at_straight_line_speed() -> void:
	var start := _player.position
	Input.action_press("ui_right")
	Input.action_press("ui_up")
	_player._physics_process(DELTA)
	assert_almost_eq((_player.position - start).length(), _player.speed * DELTA, 0.001)
