class_name OrbSpawn

## Where the next orb appears: inside the arena minus `margin`, at least
## `min_dist` away from `avoid` (the player).

const MAX_TRIES := 64


static func pick(
	rng: RandomNumberGenerator, rect: Rect2, margin: float, avoid: Vector2, min_dist: float
) -> Vector2:
	var inner := rect.grow(-margin)
	var best := inner.get_center()
	var best_dist := -1.0
	for i in MAX_TRIES:
		var p := Vector2(
			rng.randf_range(inner.position.x, inner.end.x),
			rng.randf_range(inner.position.y, inner.end.y),
		)
		var dist := p.distance_to(avoid)
		if dist >= min_dist:
			return p
		if dist > best_dist:
			best = p
			best_dist = dist
	return best
