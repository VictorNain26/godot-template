extends GutTest

# Patrol.position_at: back and forth between a and b at constant speed, as a
# pure function of elapsed time.

const A := Vector2(0, 0)
const B := Vector2(100, 0)
const SPEED := 50.0
const TOLERANCE := Vector2.ONE * 0.0001
const CASES := [
	[0.0, Vector2(0, 0)],
	[1.0, Vector2(50, 0)],
	[2.0, Vector2(100, 0)],
	[3.0, Vector2(50, 0)],
	[4.0, Vector2(0, 0)],
]


func test_position_over_time(p: Array = use_parameters(CASES)) -> void:
	assert_almost_eq(Patrol.position_at(A, B, SPEED, p[0]), p[1], TOLERANCE)


func test_same_endpoints_stay_put() -> void:
	assert_eq(Patrol.position_at(A, A, SPEED, 3.0), A)
