extends GutTest

# OrbSpawn.pick: a point inside the arena minus a margin, far enough from a
# point to avoid (the player), reproducible from the RNG seed.

const SCREEN := Rect2(0, 0, 1152, 648)
const MARGIN := 40.0
const AVOID := Vector2(576, 324)
const MIN_DIST := 150.0
const DRAWS := 200
const SEED := 12345


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_every_draw_is_inside_the_margin() -> void:
	var inner := SCREEN.grow(-MARGIN)
	var rng := _rng(SEED)
	for i in DRAWS:
		var p := OrbSpawn.pick(rng, SCREEN, MARGIN, AVOID, MIN_DIST)
		var inside := (
			p.x >= inner.position.x
			and p.x <= inner.end.x
			and p.y >= inner.position.y
			and p.y <= inner.end.y
		)
		assert_true(inside, "draw %d at %s" % [i, p])


func test_every_draw_keeps_its_distance_from_the_avoided_point() -> void:
	var rng := _rng(SEED)
	for i in DRAWS:
		var p := OrbSpawn.pick(rng, SCREEN, MARGIN, AVOID, MIN_DIST)
		assert_gte(p.distance_to(AVOID), MIN_DIST, "draw %d at %s" % [i, p])


func test_same_seed_gives_same_point() -> void:
	var first := OrbSpawn.pick(_rng(SEED), SCREEN, MARGIN, AVOID, MIN_DIST)
	var second := OrbSpawn.pick(_rng(SEED), SCREEN, MARGIN, AVOID, MIN_DIST)
	assert_eq(first, second)
