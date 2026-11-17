extends GdUnitTestSuite

# Wiring between the 2D scene, player_2d.gd and PlayerMotion; the rule's own
# cases are covered by test_player_motion.gd.

const MAIN_SCENE := "res://scenes/main_2d.tscn"
const PLAYER_SCRIPT := "res://scenes/player_2d.gd"
const DELTA := 0.5
const EPSILON := 0.001
const TOLERANCE := Vector2.ONE * EPSILON
const ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]
const DIRECTIONS := [
	["move_right", Vector2.RIGHT],
	["move_left", Vector2.LEFT],
	["move_up", Vector2.UP],
	["move_down", Vector2.DOWN],
]

var _player: Player2D
var _start: Vector2


func before_test() -> void:
	var scene: PackedScene = load(MAIN_SCENE)
	var main: Node = auto_free(scene.instantiate())
	add_child(main)
	_player = main.get_node_or_null("Player") as Player2D
	if _player != null:
		_start = _player.position


func after_test() -> void:
	for action in ACTIONS:
		Input.action_release(action)


func test_player_is_a_body_running_player_script() -> void:
	(
		assert_object(_player)
		. override_failure_message("Main must have a CharacterBody2D named Player")
		. is_not_null()
	)
	assert_object(_player.get_script()).is_same(load(PLAYER_SCRIPT))


# GdUnit4 fills test_parameters itself: it is never read by the test.
@warning_ignore("unused_parameter")
func test_each_action_moves_player_its_way(
	action: String,
	direction: Vector2,
	# gdlint:ignore = unused-argument
	test_parameters := DIRECTIONS
) -> void:
	Input.action_press(action)
	_player._physics_process(DELTA)
	var expected: Vector2 = direction * _player.speed * DELTA
	assert_vector(_player.position - _start).is_equal_approx(expected, TOLERANCE)


func test_no_input_keeps_player_still() -> void:
	_player._physics_process(DELTA)
	assert_vector(_player.position).is_equal_approx(_start, TOLERANCE)


func test_diagonal_input_moves_at_straight_line_speed() -> void:
	Input.action_press("move_right")
	Input.action_press("move_up")
	_player._physics_process(DELTA)
	var moved := (_player.position - _start).length()
	assert_float(moved).is_equal_approx(_player.speed * DELTA, EPSILON)
