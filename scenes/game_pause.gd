class_name GamePause
extends PauseMenu

## The kit's pause menu in this game: resume, options, back to the title.
## Add the game's own entries here (restart, save) and handle them in _on_chosen.

const TITLE_SCENE := "res://scenes/title.tscn"


func _init() -> void:
	# The kit's entries are these three; a game passes its own list to super().
	super()
	chosen.connect(_on_chosen)


func _on_chosen(id: StringName) -> void:
	if id == &"title":
		get_tree().paused = false
		get_tree().change_scene_to_file(TITLE_SCENE)
