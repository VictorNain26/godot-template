extends SceneTree
## Writes the scenes the template makes in code: the title screen, and the
## pause menu inside each demo. Run once with
##   godot --headless --path . -s res://tools/scenes/build_scenes.gd
## Scenes are saved through the engine, never edited by hand.


func _initialize() -> void:
	var title := Control.new()
	title.name = "Title"
	title.set_script(load("res://scenes/title.gd"))
	_save(title, "res://scenes/title.tscn")
	var check := Node.new()
	check.name = "MouseCheck"
	check.set_script(load("res://addons/kit/dev/mouse_check.gd"))
	_save(check, "res://addons/kit/dev/mouse_check.tscn")
	for path: String in ["res://scenes/main_2d.tscn", "res://scenes/main_3d.tscn"]:
		var root := (load(path) as PackedScene).instantiate()
		if root.get_node_or_null("Pause") == null:
			var pause := CanvasLayer.new()
			pause.name = "Pause"
			pause.set_script(load("res://scenes/game_pause.gd"))
			root.add_child(pause)
			pause.owner = root
			_save(root, path)
		root.free()
	quit(0)


func _save(root: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	print("%s: %s" % [path, error_string(err)])
