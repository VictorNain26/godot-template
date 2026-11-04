class_name Difficulty

## Difficulty ramp driven by the score.

const SPEED_STEP := 0.08
const SPEED_EVERY := 5
const SPEED_MAX := 2.0
const BASE_ENEMIES := 2
const ENEMY_EVERY := 10
const ENEMIES_MAX := 5


static func enemy_speed_scale(score: int) -> float:
	return minf(1.0 + SPEED_STEP * floori(score / float(SPEED_EVERY)), SPEED_MAX)


static func enemy_count(score: int) -> int:
	return mini(BASE_ENEMIES + floori(score / float(ENEMY_EVERY)), ENEMIES_MAX)
