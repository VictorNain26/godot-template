extends GutTest

# Every 7th orb (0-based index 6, 13, 20...) is a power-up, alternating time
# bonus and shield.

const CASES := [
	[0, PowerUps.Kind.NONE],
	[5, PowerUps.Kind.NONE],
	[6, PowerUps.Kind.TIME],
	[13, PowerUps.Kind.SHIELD],
	[20, PowerUps.Kind.TIME],
]


func test_kind_for_orb_index(p: Array = use_parameters(CASES)) -> void:
	assert_eq(PowerUps.kind_for(p[0]), p[1])
