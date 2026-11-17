extends RefCounted
## What the kit (addons/kit) needs to know about this game: read by the Prefs
## autoload, the export self-test and the mouse check, named by the project
## setting kit/config. Labels are French, the language of the code; their
## English is in locale/en.po. This game keeps the kit's menus (addons/kit_ui):
## a game that writes its own deletes that folder and the three calls to it
## below, then clicks its own menus in mouse_check().

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

## The licence files of the fonts the game ships: an export leaves out what is
## not a resource, and the self-test checks these made it in.
const LICENCES: Array[String] = [
	"res://addons/kit_ui/fonts/Cinzel-OFL.txt",
	"res://addons/kit_ui/fonts/AtkinsonHyperlegibleNext-OFL.txt",
]


## The look of the menus. Leave it empty to keep the kit's own look; set any
## UiStyle token here to change it (fonts, sizes, colours, radii, opacities).
## The menus' tests (addons/kit_ui/tests/test_skin.gd) then hold the result to
## the rules of a readable interface. Example:
##   UiStyle.ACCENT = Color("4fc3f7")
##   UiStyle.DISPLAY_PATH = "res://assets/fonts/MyTitles.ttf"
static func skin() -> void:
	pass


## The game's checks for the export self-test (`-- --selftest`), returning
## what failed.
static func self_test() -> Array[String]:
	return KitUiSelfTest.run()


## The clicks `mise run mouse-check` makes, with real mouse events under Xvfb.
static func mouse_check(check: MouseCheck) -> void:
	await KitUiMouseCheck.run(check)
