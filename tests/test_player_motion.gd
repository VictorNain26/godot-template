extends GutTest

const SPEED := 200.0
const EPSILON := 0.001


func test_right_input_moves_by_speed_times_delta() -> void:
	var step := PlayerMotion.displacement(Vector2.RIGHT, SPEED, 0.5)
	assert_eq(step, Vector2(100.0, 0.0))


func test_no_input_does_not_move() -> void:
	var step := PlayerMotion.displacement(Vector2.ZERO, SPEED, 0.5)
	assert_eq(step, Vector2.ZERO)


func test_diagonal_input_is_capped_to_speed() -> void:
	var step := PlayerMotion.displacement(Vector2(1.0, 1.0), SPEED, 1.0)
	assert_almost_eq(step.length(), SPEED, EPSILON)


func test_zero_delta_does_not_move() -> void:
	var step := PlayerMotion.displacement(Vector2.RIGHT, SPEED, 0.0)
	assert_eq(step, Vector2.ZERO)


func test_partial_analog_input_keeps_its_strength() -> void:
	var step := PlayerMotion.displacement(Vector2(0.3, 0.0), SPEED, 1.0)
	assert_almost_eq(step, Vector2(0.3 * SPEED, 0.0), Vector2.ONE * EPSILON)


func test_input_longer_than_one_is_capped_to_speed() -> void:
	var step := PlayerMotion.displacement(Vector2(3.0, 4.0), SPEED, 1.0)
	assert_almost_eq(step.length(), SPEED, EPSILON)


func test_ground_displacement_maps_input_x_to_x() -> void:
	var step := PlayerMotion.ground_displacement(Vector2.RIGHT, SPEED, 0.5)
	assert_almost_eq(step, Vector3(100.0, 0.0, 0.0), Vector3.ONE * EPSILON)


func test_ground_displacement_maps_input_y_to_z() -> void:
	var step := PlayerMotion.ground_displacement(Vector2.DOWN, SPEED, 0.5)
	assert_almost_eq(step, Vector3(0.0, 0.0, 100.0), Vector3.ONE * EPSILON)


func test_ground_displacement_caps_diagonal_to_speed() -> void:
	var step := PlayerMotion.ground_displacement(Vector2(1.0, 1.0), SPEED, 1.0)
	assert_almost_eq(step.length(), SPEED, EPSILON)
