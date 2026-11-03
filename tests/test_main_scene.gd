extends GutTest

# Wiring only: the movement rule itself is covered by test_player_motion.gd.

const MAIN_SCENE := "res://scenes/main.tscn"
const DELTA := 0.5

var _sender: GutInputSender = InputSender.new(Input)
var _player: CharacterBody2D
var _start: Vector2


func before_each() -> void:
	var main: Node = add_child_autofree(load(MAIN_SCENE).instantiate())
	_player = main.get_node("Player") as CharacterBody2D
	_start = _player.position


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_main_scene_has_player_body() -> void:
	assert_not_null(_player, "Main must have a CharacterBody2D named Player")


func test_right_input_moves_player_right() -> void:
	_sender.action_down("ui_right")
	_player._physics_process(DELTA)
	assert_eq(_player.position - _start, Vector2(_player.speed * DELTA, 0.0))


func test_no_input_keeps_player_still() -> void:
	_player._physics_process(DELTA)
	assert_eq(_player.position, _start)
