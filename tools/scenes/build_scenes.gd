extends SceneTree
## Writes the scenes the template makes in code: the title screen, the kit's
## mouse check, and the pause menu inside each demo. Run once with
##   godot --headless --path . -s res://tools/scenes/build_scenes.gd
## These scenes are saved through the engine, never edited by hand.


func _initialize() -> void:
	var title := Control.new()
	title.name = "Title"
	title.set_script(load("res://scenes/title.gd"))
	_save(title, "res://scenes/title.tscn")
	title.free()
	var check := Node.new()
	check.name = "MouseCheck"
	check.set_script(load("res://addons/kit/dev/mouse_check.gd"))
	_save(check, "res://addons/kit/dev/mouse_check.tscn")
	check.free()
	for file in DirAccess.get_files_at("res://scenes"):
		if not (file.begins_with("main_") and file.ends_with(".tscn")):
			continue
		var path := "res://scenes/" + file
		var scene := (load(path) as PackedScene).instantiate()
		if scene.get_node_or_null("Pause") == null:
			var pause := CanvasLayer.new()
			pause.name = "Pause"
			pause.set_script(load("res://scenes/game_pause.gd"))
			scene.add_child(pause)
			pause.owner = scene
			_save(scene, path)
		scene.free()
	quit(0)


func _save(scene: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(scene)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s: %s" % [path, error_string(err)])
