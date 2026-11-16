extends RefCounted
## What the kit (addons/kit) needs to know about this game: read by the Prefs
## autoload, named by the project setting kit/config. Labels are French, the
## language of the code; their English is in locale/en.po.

## The actions the player may rebind in Options > Keys, with the name the menu shows.
const ACTIONS := {
	&"move_up": "Monter",
	&"move_down": "Descendre",
	&"move_left": "Gauche",
	&"move_right": "Droite",
	&"interact": "Agir",
}
## Not offered for rebinding, but kept off the keys the player takes.
const FIXED_ACTIONS: Array[StringName] = [&"pause"]
## The legend of the title and pause screens: [label, [actions]].
const HELP: Array[Array] = [
	["Marcher", [&"move_up", &"move_left", &"move_down", &"move_right"]],
	["Agir", [&"interact"]],
	["Pause", [&"pause"]],
]


## The look of the menus. Leave it empty to keep the kit's own look; set any
## UiStyle token here to change it (fonts, sizes, colours, radii, opacities).
## The kit's tests (addons/kit/tests/test_skin.gd) then hold the result to
## the rules of a readable interface. Example:
##   UiStyle.ACCENT = Color("4fc3f7")
##   UiStyle.DISPLAY_PATH = "res://assets/fonts/MyTitles.ttf"
static func skin() -> void:
	pass
