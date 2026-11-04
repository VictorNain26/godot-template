class_name PowerUps

## Which orb is a power-up: every 7th one, alternating time bonus and shield.

enum Kind { NONE, TIME, SHIELD }

const EVERY := 7


static func kind_for(index: int) -> Kind:
	if (index + 1) % EVERY != 0:
		return Kind.NONE
	var nth := (index + 1) / EVERY
	return Kind.TIME if nth % 2 == 1 else Kind.SHIELD
