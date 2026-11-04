class_name Game
extends Node2D

## Orb Rush 2D: wires RoundState, orbs, enemies, player and HUD. Rules live in
## src/ (RoundState, OrbSpawn, Patrol, Arena); this script only connects them.

const ROUND_SECONDS := 60.0
const ARENA := Rect2(0, 0, 1152, 648)
const ORB_MARGIN := 48.0
const ORB_MIN_DIST := 160.0
const ORB_SCENE := preload("res://scenes/orb.tscn")
const SHAKE_STRENGTH := 12.0
const SHAKE_TIME := 0.35

@export var rng_seed: int = 1

var round: RoundState
var _rng := RandomNumberGenerator.new()

@onready var _player: Player2D = $Player
@onready var _orbs: Node2D = $Orbs
@onready var _enemies: Node2D = $Enemies
@onready var _score: Label = $Hud/Score
@onready var _time: Label = $Hud/Time
@onready var _game_over: Control = $Hud/GameOver
@onready var _final: Label = $Hud/GameOver/Box/Final
@onready var _camera: Camera2D = $Camera
@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	for enemy: Enemy in _enemies.get_children():
		enemy.touched_player.connect(_on_enemy_touched)
	_start()


func _process(delta: float) -> void:
	if round.over:
		return
	round.tick(delta)
	if round.over:
		_end()
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if round.over and event.is_action_pressed("restart"):
		_start()


func _start() -> void:
	round = RoundState.new(ROUND_SECONDS)
	_rng.seed = rng_seed
	_player.position = ARENA.get_center()
	for enemy: Enemy in _enemies.get_children():
		enemy.reset()
	for orb in _orbs.get_children():
		_orbs.remove_child(orb)
		orb.queue_free()
	_spawn_orb()
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
	orb.position = OrbSpawn.pick(_rng, ARENA, ORB_MARGIN, _player.position, ORB_MIN_DIST)
	orb.collected.connect(_on_orb_collected)
	_orbs.add_child(orb)


func _on_orb_collected(orb: Orb) -> void:
	if round.over:
		return
	round.collect()
	_burst.position = orb.position
	_burst.restart()
	_replace_orb.call_deferred(orb)
	_refresh_hud()


func _replace_orb(orb: Orb) -> void:
	_orbs.remove_child(orb)
	orb.queue_free()
	_spawn_orb()


func _on_enemy_touched() -> void:
	if round.over:
		return
	round.hit()
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
