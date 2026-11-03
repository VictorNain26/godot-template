class_name PlayerMotion

## Pure movement rule, kept out of nodes so it runs in headless tests.


static func displacement(input: Vector2, speed: float, delta: float) -> Vector2:
	return input.limit_length(1.0) * speed * delta


## Same rule on the 3D ground plane: input x drives x, input y drives z.
static func ground_displacement(input: Vector2, speed: float, delta: float) -> Vector3:
	var step := displacement(input, speed, delta)
	return Vector3(step.x, 0.0, step.y)
