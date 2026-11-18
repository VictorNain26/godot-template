class_name OwnMenu
extends Control
## A menu the game writes itself, with an engine Button and no kit_ui.

var clicks := 0
var play := Button.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play.text = Loc.t("Jouer")
	play.position = Vector2(100, 100)
	play.size = Vector2(240, 64)
	play.pressed.connect(func() -> void: clicks += 1)
	add_child(play)
