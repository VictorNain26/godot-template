extends GutTest

# Difficulty ramps with the score: enemies speed up every 5 points (capped at
# x2.0) and one enemy is added every 10 points (capped at 5).

const EPSILON := 0.0001
const SPEED_CASES := [[0, 1.0], [4, 1.0], [5, 1.08], [50, 1.8], [100, 2.0]]
const COUNT_CASES := [[0, 2], [9, 2], [10, 3], [30, 5], [99, 5]]


func test_enemy_speed_scale(p: Array = use_parameters(SPEED_CASES)) -> void:
	assert_almost_eq(Difficulty.enemy_speed_scale(p[0]), p[1] as float, EPSILON)


func test_enemy_count(p: Array = use_parameters(COUNT_CASES)) -> void:
	assert_eq(Difficulty.enemy_count(p[0]), p[1])
