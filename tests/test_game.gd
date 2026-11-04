extends GutTest

# Wiring of the Orb Rush 2D scene: game.gd ties RoundState, orbs, enemies,
# player and HUD together. The rules themselves are covered by their own tests.

const GAME_SCENE := "res://scenes/main_2d.tscn"
const CENTER := Vector2(576, 324)
const EPSILON := 0.001
const RESTART_TICK_TOLERANCE := 0.1

var _sender := GutInputSender.new(Input)
var _game: Game


func before_each() -> void:
	var scene: PackedScene = load(GAME_SCENE)
	_game = scene.instantiate() as Game
	add_child_autofree(_game)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_scene_has_player_two_enemies_one_orb_and_hud() -> void:
	assert_not_null(_game, "main_2d.tscn root must run game.gd")
	assert_not_null(_game.get_node_or_null("Player") as Player2D)
	assert_eq(_game.get_node("Enemies").get_child_count(), 2)
	assert_eq(_game.get_node("Orbs").get_child_count(), 1)
	assert_not_null(_game.get_node_or_null("Hud/Score") as Label)
	assert_not_null(_game.get_node_or_null("Hud/Time") as Label)
	assert_not_null(_game.get_node_or_null("Hud/GameOver") as Control)


func test_round_starts_at_sixty_seconds_with_player_in_the_center() -> void:
	assert_almost_eq(_game.round.time_left, 60.0, EPSILON)
	assert_eq(_game.round.score, 0)
	assert_eq((_game.get_node("Player") as Node2D).position, CENTER)
	assert_false((_game.get_node("Hud/GameOver") as Control).visible)


func test_time_label_counts_down() -> void:
	_game._process(1.0)
	assert_eq((_game.get_node("Hud/Time") as Label).text, "59")


func test_player_on_orb_scores_one_and_respawns_it_elsewhere() -> void:
	var orb := _game.get_node("Orbs").get_child(0) as Node2D
	var before := orb.global_position
	(_game.get_node("Player") as Node2D).global_position = before
	await wait_physics_frames(3)
	assert_eq(_game.round.score, 1)
	assert_eq((_game.get_node("Hud/Score") as Label).text, "1")
	var next := _game.get_node("Orbs").get_child(0) as Node2D
	assert_ne(next.global_position, before)


func test_enemy_contact_ends_round_and_shows_game_over() -> void:
	var enemy := _game.get_node("Enemies").get_child(0) as Node2D
	(_game.get_node("Player") as Node2D).global_position = enemy.global_position
	await wait_physics_frames(3)
	assert_true(_game.round.over)
	assert_true((_game.get_node("Hud/GameOver") as Control).visible)


func test_restart_action_after_game_over_resets_the_round() -> void:
	_game.round.collect()
	_game.round.hit()
	(_game.get_node("Player") as Node2D).position = Vector2(100, 100)
	_sender.action_down("restart")
	await wait_process_frames(2)
	assert_eq(_game.round.score, 0)
	# The new round has already ticked for the awaited frames.
	assert_almost_eq(_game.round.time_left, 60.0, RESTART_TICK_TOLERANCE)
	assert_false(_game.round.over)
	assert_eq((_game.get_node("Player") as Node2D).position, CENTER)
	assert_false((_game.get_node("Hud/GameOver") as Control).visible)


func test_player_pushed_left_stops_at_the_arena_edge() -> void:
	var player := _game.get_node("Player") as Player2D
	_sender.action_down("move_left")
	player._physics_process(10.0)
	assert_almost_eq(player.position.x, 16.0, EPSILON)
