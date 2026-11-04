class_name Patrol

## Back-and-forth path between a and b at constant speed, as a pure function of
## elapsed time so enemies never drift.


static func position_at(a: Vector2, b: Vector2, speed: float, t: float) -> Vector2:
	var length := a.distance_to(b)
	if length == 0.0:
		return a
	var travelled := pingpong(speed * t, length)
	return a + (b - a) / length * travelled
