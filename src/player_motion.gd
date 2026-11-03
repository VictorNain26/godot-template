class_name PlayerMotion

## Pure movement rule, kept out of nodes so it runs in headless tests.


static func displacement(input: Vector2, speed: float, delta: float) -> Vector2:
	return input.limit_length(1.0) * speed * delta
