extends GutTest

# Wiring between the 3D scene, player_3d.gd and PlayerMotion; the rule's own
# cases are covered by test_player_motion.gd.

const MAIN_SCENE := "res://scenes/main_3d.tscn"
const PLAYER_SCRIPT := "res://scenes/player_3d.gd"
const DELTA := 0.5
const EPSILON := 0.001
const DIRECTIONS := [
	["move_right", Vector3.RIGHT],
	["move_left", Vector3.LEFT],
	["move_up", Vector3.FORWARD],
	["move_down", Vector3.BACK],
]

var _sender := GutInputSender.new(Input)
var _player: Player3D
var _start: Vector3


func before_each() -> void:
	var scene: PackedScene = load(MAIN_SCENE)
	var main: Node = add_child_autofree(scene.instantiate())
	_player = main.get_node_or_null("Player") as Player3D
	if _player != null:
		_start = _player.position


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_player_is_a_body_running_player_script() -> void:
	assert_not_null(_player, "Main3D must have a CharacterBody3D named Player")
	assert_eq(_player.get_script(), load(PLAYER_SCRIPT))


func test_each_action_moves_player_its_way(p: Array = use_parameters(DIRECTIONS)) -> void:
	_sender.action_down(p[0])
	_player._physics_process(DELTA)
	var direction: Vector3 = p[1]
	var expected := direction * _player.speed * DELTA
	var tolerance := Vector3(EPSILON, EPSILON, EPSILON)
	assert_almost_eq(_player.position - _start, expected, tolerance)


func test_no_input_keeps_player_still() -> void:
	_player._physics_process(DELTA)
	assert_almost_eq(_player.position, _start, Vector3(EPSILON, EPSILON, EPSILON))


func test_diagonal_input_moves_at_straight_line_speed() -> void:
	_sender.action_down("move_right")
	_sender.action_down("move_up")
	_player._physics_process(DELTA)
	assert_almost_eq((_player.position - _start).length(), _player.speed * DELTA, EPSILON)
