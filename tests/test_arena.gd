extends GutTest

# Arena.clamp_point keeps a body of half-extent `half` inside a rectangle.

const SCREEN := Rect2(0, 0, 1152, 648)
const FLOOR_3D := Rect2(-10, -10, 20, 20)


func test_point_past_left_edge_is_pushed_back_in() -> void:
	assert_eq(Arena.clamp_point(Vector2(-10, 300), SCREEN, 16.0), Vector2(16, 300))


func test_point_past_bottom_right_corner_is_pushed_back_in() -> void:
	assert_eq(Arena.clamp_point(Vector2(2000, 2000), SCREEN, 16.0), Vector2(1136, 632))


func test_point_inside_does_not_move() -> void:
	assert_eq(Arena.clamp_point(Vector2(576, 324), SCREEN, 16.0), Vector2(576, 324))


func test_rect_centred_on_origin_for_3d_floor() -> void:
	assert_eq(Arena.clamp_point(Vector2(15, -15), FLOOR_3D, 0.5), Vector2(9.5, -9.5))
