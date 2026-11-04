class_name Game
extends Node2D

## Orb Rush 2D: wires RoundState, Combo, Difficulty, PowerUps, orbs, enemies,
## player and HUD. Rules live in src/; this script only connects them.

const ROUND_SECONDS := 60.0
const ARENA := Rect2(0, 0, 1152, 648)
const ORB_MARGIN := 48.0
const ORB_MIN_DIST := 160.0
const COMBO_WINDOW := 2.0
const TIME_BONUS := 5.0
const ORB_SCENE := preload("res://scenes/orb.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
## Patrol lanes for enemies beyond the two placed in the scene, in spawn order.
const EXTRA_LANES := [
	[Vector2(120, 80), Vector2(120, 570), 120.0],
	[Vector2(1030, 570), Vector2(1030, 80), 120.0],
	[Vector2(300, 80), Vector2(850, 570), 150.0],
]
const SHAKE_STRENGTH := 12.0
const SHAKE_TIME := 0.35
const POPUP_RISE := 48.0
const POPUP_TIME := 0.8
const POPUP_SETTINGS := preload("res://ui/popup_label.tres")

@export var rng_seed: int = 1

var round: RoundState
var _rng := RandomNumberGenerator.new()
var _combo: Combo
var _elapsed := 0.0
var _orb_index := 0
var _base_enemies := 0

@onready var _player: Player2D = $Player
@onready var _shield: Node2D = $Player/Shield
@onready var _orbs: Node2D = $Orbs
@onready var _enemies: Node2D = $Enemies
@onready var _popups: Node2D = $Popups
@onready var _score: Label = $Hud/Score
@onready var _time: Label = $Hud/Time
@onready var _game_over: Control = $Hud/GameOver
@onready var _final: Label = $Hud/GameOver/Box/Final
@onready var _camera: Camera2D = $Camera
@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	_base_enemies = _enemies.get_child_count()
	for enemy: Enemy in _enemies.get_children():
		enemy.touched_player.connect(_on_enemy_touched)
	_start()


func _process(delta: float) -> void:
	if round.over:
		return
	_elapsed += delta
	round.tick(delta)
	if round.over:
		_end()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if round.over and event.is_action_pressed("restart"):
		_start()


func _start() -> void:
	round = RoundState.new(ROUND_SECONDS)
	_combo = Combo.new(COMBO_WINDOW)
	_elapsed = 0.0
	_orb_index = 0
	_rng.seed = rng_seed
	_player.position = ARENA.get_center()
	while _enemies.get_child_count() > _base_enemies:
		var extra := _enemies.get_child(_enemies.get_child_count() - 1)
		_enemies.remove_child(extra)
		extra.queue_free()
	for orb in _orbs.get_children():
		_orbs.remove_child(orb)
		orb.queue_free()
	_spawn_orb()
	_apply_difficulty()
	_set_playing(true)
	_refresh_hud()


func _end() -> void:
	_set_playing(false)
	_final.text = "Score %d" % round.score


func _set_playing(playing: bool) -> void:
	_player.set_physics_process(playing)
	for enemy in _enemies.get_children():
		enemy.set_physics_process(playing)
	_game_over.visible = not playing


func _spawn_orb() -> void:
	var orb: Orb = ORB_SCENE.instantiate()
	orb.kind = PowerUps.kind_for(_orb_index)
	orb.position = OrbSpawn.pick(_rng, ARENA, ORB_MARGIN, _player.position, ORB_MIN_DIST)
	orb.collected.connect(_on_orb_collected)
	_orbs.add_child(orb)
	_orb_index += 1


func _apply_difficulty() -> void:
	var wanted := Difficulty.enemy_count(round.score)
	while _enemies.get_child_count() < wanted:
		var lane: Array = EXTRA_LANES[_enemies.get_child_count() - _base_enemies]
		var enemy: Enemy = ENEMY_SCENE.instantiate()
		enemy.point_a = lane[0]
		enemy.point_b = lane[1]
		enemy.speed = lane[2]
		enemy.touched_player.connect(_on_enemy_touched)
		_enemies.add_child(enemy)
	var scale_factor := Difficulty.enemy_speed_scale(round.score)
	for enemy: Enemy in _enemies.get_children():
		enemy.speed_scale = scale_factor


func _on_orb_collected(orb: Orb) -> void:
	if round.over:
		return
	var multiplier := _combo.register(_elapsed)
	round.collect(multiplier)
	var text := "+%d" % multiplier
	if multiplier > 1:
		text += " x%d" % multiplier
	match orb.kind:
		PowerUps.Kind.TIME:
			round.add_time(TIME_BONUS)
			text += "  +%ds" % TIME_BONUS
		PowerUps.Kind.SHIELD:
			round.shield = true
			text += "  BOUCLIER"
	_popup(text, orb.position, Orb.COLORS[orb.kind])
	_burst.position = orb.position
	_burst.color = Orb.COLORS[orb.kind]
	_burst.restart()
	_replace_orb.call_deferred(orb)
	_refresh_hud()


func _replace_orb(orb: Orb) -> void:
	_orbs.remove_child(orb)
	orb.queue_free()
	_spawn_orb()
	_apply_difficulty()


func _popup(text: String, at: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.label_settings = POPUP_SETTINGS
	label.modulate = color
	label.position = at + Vector2(-20, -40)
	_popups.add_child(label)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - POPUP_RISE, POPUP_TIME)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_TIME).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)


func _on_enemy_touched() -> void:
	if round.over:
		return
	round.hit()
	if round.over:
		_end()
	_refresh_hud()
	_shake()


func _shake() -> void:
	var tween := create_tween()
	for i in 6:
		var offset := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * SHAKE_STRENGTH
		tween.tween_property(_camera, "offset", offset, SHAKE_TIME / 7.0)
	tween.tween_property(_camera, "offset", Vector2.ZERO, SHAKE_TIME / 7.0)


func _refresh_hud() -> void:
	_score.text = str(round.score)
	_time.text = str(ceili(round.time_left))
	_shield.visible = round.shield
