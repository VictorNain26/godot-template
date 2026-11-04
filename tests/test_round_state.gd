extends GutTest

# RoundState rules from the Orb Rush plan: a 60 s round, +1 per orb, a hit ends it.

const DURATION := 60.0
const EPSILON := 0.0001

var _round: RoundState


func before_each() -> void:
	_round = RoundState.new(DURATION)


func test_new_round_is_full_time_zero_score_not_over() -> void:
	assert_almost_eq(_round.time_left, 60.0, EPSILON)
	assert_eq(_round.score, 0)
	assert_false(_round.over)


func test_tick_counts_time_down() -> void:
	_round.tick(1.0)
	assert_almost_eq(_round.time_left, 59.0, EPSILON)
	assert_false(_round.over)


func test_tick_past_the_end_stops_at_zero_and_ends_round() -> void:
	_round.tick(61.0)
	assert_almost_eq(_round.time_left, 0.0, EPSILON)
	assert_true(_round.over)


func test_collect_adds_one_point() -> void:
	_round.collect()
	assert_eq(_round.score, 1)


func test_collect_after_the_end_is_ignored() -> void:
	_round.tick(61.0)
	_round.collect()
	assert_eq(_round.score, 0)


func test_hit_ends_round_and_keeps_time_left() -> void:
	_round.tick(10.0)
	_round.hit()
	assert_true(_round.over)
	assert_almost_eq(_round.time_left, 50.0, EPSILON)


func test_collect_adds_the_given_points() -> void:
	_round.collect(3)
	assert_eq(_round.score, 3)


func test_add_time_extends_the_round() -> void:
	_round.tick(50.0)
	_round.add_time(5.0)
	assert_almost_eq(_round.time_left, 15.0, EPSILON)


func test_add_time_after_the_end_does_nothing() -> void:
	_round.hit()
	_round.add_time(5.0)
	assert_almost_eq(_round.time_left, 60.0, EPSILON)


func test_hit_with_shield_spends_it_and_keeps_playing() -> void:
	_round.shield = true
	_round.hit()
	assert_false(_round.over)
	assert_false(_round.shield)


func test_second_hit_after_shield_ends_round() -> void:
	_round.shield = true
	_round.hit()
	_round.hit()
	assert_true(_round.over)


func test_tick_after_the_end_changes_nothing() -> void:
	_round.tick(10.0)
	_round.hit()
	_round.tick(5.0)
	assert_almost_eq(_round.time_left, 50.0, EPSILON)
