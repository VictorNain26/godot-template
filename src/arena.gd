class_name Arena

## Keeps a body of half-extent `half` inside `rect` (screen in 2D, floor x/z in 3D).


static func clamp_point(p: Vector2, rect: Rect2, half: float) -> Vector2:
	var low := rect.position + Vector2.ONE * half
	var high := rect.end - Vector2.ONE * half
	return p.clamp(low, high)
