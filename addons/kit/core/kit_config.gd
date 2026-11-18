class_name KitConfig
extends RefCounted
## Finds the game's kit config: the script the project setting kit/config
## names (res://kit_config.gd by default). Prefs reads its actions and skin,
## the self-test its checks and licences, the mouse check its clicks. Part
## of the kit (addons/kit).

const SETTING := "kit/config"
const DEFAULT := "res://kit_config.gd"


## The game's kit config, or null when the project has none.
static func find() -> GDScript:
	var path := str(ProjectSettings.get_setting(SETTING, DEFAULT))
	if not ResourceLoader.exists(path):
		return null
	return load(path) as GDScript


## One constant of the kit config, or `fallback` when there is no config or
## no such constant.
static func constant(name: String, fallback: Variant) -> Variant:
	var config := find()
	if config == null:
		return fallback
	return config.get_script_constant_map().get(name, fallback)
