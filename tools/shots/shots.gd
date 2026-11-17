extends Node
## Saves a picture of the title, the options, a demo and its pause menu, to
## read the interface without the editor: `mise run shots` (OUT=dir, under
## Xvfb). Add the game's own screens here as it grows.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Prefs.persist = false
	Prefs.settings = Settings.new()
	Prefs.apply()
	var title: Node = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	await _shot("title")
	var menu: OptionsMenu = title.get("_menu")
	menu.open()
	await _shot("options")
	title.free()
	var demo: Node = (load(Title.START_SCENE) as PackedScene).instantiate()
	add_child(demo)
	await _shot("demo")
	KitSim.tap(KitSim.key(KEY_ESCAPE))
	await _shot("pause")
	get_tree().quit()


func _shot(label: String) -> void:
	for i in 6:
		await get_tree().process_frame
	var out := OS.get_environment("OUT")
	var path := (out if out != "" else "build/shots") + "/" + label + ".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	print("SHOT ", path, " ", get_viewport().get_texture().get_image().save_png(path))
