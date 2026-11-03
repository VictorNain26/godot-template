extends GutTest

# Wiring between the scene, player.gd and PlayerMotion; the rule's own cases
# are covered by test_player_motion.gd.

const MAIN_SCENE := "res://scenes/main.tscn"
const PLAYER_SCRIPT := "res://scenes/player.gd"
const DELTA := 0.5
const EPSILON := 0.001
const DIRECTIONS := [
	["ui_right", Vector2.RIGHT],
	["ui_left", Vector2.LEFT],
	["ui_up", Vector2.UP],
	["ui_down", Vector2.DOWN],
]

var _sender: GutInputSender = InputSender.new(Input)
var _player: CharacterBody2D
var _start: Vector2


func before_each() -> void:
	var main: Node = add_child_autofree(load(MAIN_SCENE).instantiate())
	_player = main.get_node_or_null("Player") as CharacterBody2D
	if _player != null:
		_start = _player.position


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_player_is_a_body_running_player_script() -> void:
	assert_not_null(_player, "Main must have a CharacterBody2D named Player")
	assert_eq(_player.get_script(), load(PLAYER_SCRIPT))


func test_each_action_moves_player_its_way(p: Array = use_parameters(DIRECTIONS)) -> void:
	_sender.action_down(p[0])
	_player._physics_process(DELTA)
	var expected: Vector2 = p[1] * _player.speed * DELTA
	assert_almost_eq(_player.position - _start, expected, Vector2(EPSILON, EPSILON))


func test_no_input_keeps_player_still() -> void:
	_player._physics_process(DELTA)
	assert_almost_eq(_player.position, _start, Vector2(EPSILON, EPSILON))


func test_diagonal_input_moves_at_straight_line_speed() -> void:
	_sender.action_down("ui_right").action_down("ui_up")
	_player._physics_process(DELTA)
	assert_almost_eq((_player.position - _start).length(), _player.speed * DELTA, EPSILON)
