class_name GamePause
extends PauseMenu

## The kit's pause menu in this game: resume, options, back to the title.
## Add the game's own entries here (restart, save) and handle them in _on_chosen.

const TITLE_SCENE := "res://scenes/title.tscn"


func _init() -> void:
	super([[&"resume", "Reprendre"], [&"options", "Options"], [&"title", "Écran titre"]])
	chosen.connect(_on_chosen)


func _on_chosen(id: StringName) -> void:
	if id == &"title":
		get_tree().change_scene_to_file(TITLE_SCENE)
