extends GutTest

# Combo: collecting again within 2.0 s raises the multiplier (max x5); a longer
# gap resets it to x1.

var _combo: Combo


func before_each() -> void:
	_combo = Combo.new(2.0)


func test_first_collect_is_times_one() -> void:
	assert_eq(_combo.register(0.0), 1)


func test_quick_collects_raise_the_multiplier() -> void:
	assert_eq(_combo.register(0.0), 1)
	assert_eq(_combo.register(1.0), 2)
	assert_eq(_combo.register(2.5), 3)


func test_multiplier_is_capped_at_five() -> void:
	var last := 0
	for i in 6:
		last = _combo.register(i * 0.5)
	assert_eq(last, 5)


func test_gap_longer_than_window_resets_to_one() -> void:
	_combo.register(0.0)
	_combo.register(1.0)
	assert_eq(_combo.register(3.5), 1)
