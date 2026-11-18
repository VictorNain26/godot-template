class_name UiStyle
extends RefCounted

## The look of the menus: two typefaces, one type scale, one spacing unit, a
## few colours, one panel, one way to show what is selected. Every value is a
## static var: a game gives its menus another look by setting them from its
## skin (see addons/kit/README.md), and the kit's tests then check that look
## against the rules of a readable interface, whatever it is.

# Tokens read like constants (UiStyle.BODY) but stay settable by a skin.
# gdlint: disable=class-variable-name
## Cinzel for the name of the game and the headings, Atkinson Hyperlegible
## Next for everything that is read. Both under the SIL Open Font License.
static var DISPLAY_PATH := "res://addons/kit_ui/fonts/Cinzel.ttf"
static var BODY_PATH := "res://addons/kit_ui/fonts/AtkinsonHyperlegibleNext.ttf"
## The licence travels with each font, in the repository and in a build.
static var LICENCES: Array[String] = [
	"res://addons/kit_ui/fonts/Cinzel-OFL.txt",
	"res://addons/kit_ui/fonts/AtkinsonHyperlegibleNext-OFL.txt",
]

## Colours. INK is the dark of panels and outlines, TEXT what is read on it,
## ACCENT the headings and the selection, ACCENT_HOT the selected text, EDGE
## the thin border of a panel and its rules.
static var INK := Color("14101f")
static var TEXT := Color("f6ead8")
static var ACCENT := Color("ff9a3c")
static var ACCENT_HOT := Color("ffe6b0")
static var EDGE := Color("9b86e8")

## Type sizes in pixels on a 1280 by 720 screen, before the player's text
## scale. LOGO is the name of the game, TITLE the line that ends a run.
## Nothing is drawn smaller than SMALL.
static var LOGO := 104
static var TITLE := 64
static var HEADING := 44
static var BANNER := 32
static var MENU := 28
static var BODY := 24
static var HUD := 24
static var SMALL := 20

## Weights on the variable axis of each face.
static var REGULAR := 500
static var STRONG := 700
## Letter spacing of the display face, as a share of the type size.
static var TRACKING := 0.06
## Height of a line of running text, as a multiple of the type size.
static var LINE_HEIGHT := 1.5

## Spacing: everything is a multiple of UNIT; MARGIN is kept free at the edges.
static var UNIT := 8
static var MARGIN := 48
static var RADIUS := 10
static var PLATE_RADIUS := 8
static var FOCUS_RADIUS := 6
static var FOCUS_BAR := 3
## Padding above and below the text of a menu row.
static var ROW_PAD := 8

## Opacities. SECONDARY is for text that is not the main thing on its panel.
static var SECONDARY := 0.72
static var PANEL_ALPHA := 0.92
static var PLATE_ALPHA := 0.66
static var VEIL_ALPHA := 0.8
static var PAGE_ALPHA := 0.9
static var FOCUS_ALPHA := 0.2
static var BORDER_ALPHA := 0.35

# gdlint: enable=class-variable-name
static var _cache := {}


## Forgets the fonts and boxes built from the tokens: a skin calls it after
## changing them.
static func reset() -> void:
	_cache.clear()


## WCAG contrast ratio between two colours, from 1 to 21 (MenuContract's).
static func contrast(a: Color, b: Color) -> float:
	return MenuContract.contrast(a, b)


## Relative luminance (MenuContract's).
static func luminance(c: Color) -> float:
	return MenuContract.luminance(c)


## The [text, under] colours of a menu row, for MenuContract: plain and
## selected text, on a panel over the brightest and the darkest ground.
static func row_colours() -> Array:
	var out: Array = []
	for ground: Color in [Color.WHITE, Color.BLACK]:
		var under := over(INK, PANEL_ALPHA, ground)
		out.append([over(TEXT, SECONDARY, under), under])
		out.append([ACCENT_HOT, over(ACCENT, FOCUS_ALPHA, under)])
	return out


## `top` painted at `alpha` over `under`.
static func over(top: Color, alpha: float, under: Color) -> Color:
	return Color(under, 1.0).lerp(Color(top, 1.0), alpha)


## The display face, letter-spaced for `size`.
static func display(size: int, weight: int = STRONG) -> Font:
	return _font(DISPLAY_PATH, weight, roundi(size * TRACKING), 0, false)


## The reading face.
static func body(weight: int = REGULAR) -> Font:
	return _font(BODY_PATH, weight, 0, 0, false)


## The reading face with figures of one width, so a running timer or a
## counter does not shake.
static func figures(weight: int = STRONG) -> Font:
	return _font(BODY_PATH, weight, 0, 0, true)


## The reading face with LINE_HEIGHT between lines at `size`, for paragraphs.
static func reading(size: int) -> Font:
	var plain := body()
	var extra := roundi(size * LINE_HEIGHT - plain.get_height(size))
	return _font(BODY_PATH, REGULAR, 0, maxi(extra, 0), false)


## Dark rounded panel: menus, dialogue, the map.
static func panel() -> StyleBoxFlat:
	if not _cache.has("panel"):
		var box := _box(Color(INK, PANEL_ALPHA), RADIUS)
		box.set_border_width_all(1)
		box.border_color = Color(EDGE, BORDER_ALPHA)
		box.shadow_size = UNIT
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.set_content_margin_all(UNIT * 3)
		_cache["panel"] = box
	return _cache["panel"]


## Lighter plate behind something written over the game.
static func plate() -> StyleBoxFlat:
	if not _cache.has("plate"):
		_cache["plate"] = _box(Color(INK, PLATE_ALPHA), PLATE_RADIUS)
	return _cache["plate"]


## What is selected: a filled plate with a bar on its left edge.
static func focus() -> StyleBoxFlat:
	if not _cache.has("focus"):
		var box := _box(Color(ACCENT, FOCUS_ALPHA), FOCUS_RADIUS)
		box.border_width_left = FOCUS_BAR
		box.border_color = ACCENT
		_cache["focus"] = box
	return _cache["focus"]


## A key of the keyboard, as legends and prompts show it.
static func keycap() -> StyleBoxFlat:
	if not _cache.has("keycap"):
		var box := _box(Color(TEXT, 0.14), FOCUS_RADIUS)
		box.set_border_width_all(1)
		box.border_width_bottom = 3
		box.border_color = Color(TEXT, 0.6)
		_cache["keycap"] = box
	return _cache["keycap"]


## The tab that names who is speaking.
static func tab() -> StyleBoxFlat:
	if not _cache.has("tab"):
		_cache["tab"] = _box(ACCENT, FOCUS_RADIUS)
	return _cache["tab"]


## Theme for the Control nodes of the game: the reading face everywhere, the
## panel, a thin scroll bar.
static func theme() -> Theme:
	if _cache.has("theme"):
		return _cache["theme"]
	var t := Theme.new()
	t.default_font = body()
	t.default_font_size = BODY
	t.set_color(&"font_color", &"Label", TEXT)
	t.set_stylebox(&"panel", &"PanelContainer", panel())
	t.set_stylebox(&"scroll", &"VScrollBar", _bar(Color(TEXT, 0.08)))
	t.set_stylebox(&"scroll_focus", &"VScrollBar", _bar(Color(TEXT, 0.08)))
	for item: StringName in [&"grabber", &"grabber_highlight", &"grabber_pressed"]:
		t.set_stylebox(item, &"VScrollBar", _bar(Color(TEXT, 0.45)))
	_cache["theme"] = t
	return t


static func _box(colour: Color, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


static func _bar(colour: Color) -> StyleBoxFlat:
	var box := _box(colour, 3)
	box.content_margin_left = 3.0
	box.content_margin_right = 3.0
	return box


static func _font(path: String, weight: int, glyph: int, line: int, tabular: bool) -> Font:
	var key := "%s %d %d %d %s" % [path, weight, glyph, line, tabular]
	if not _cache.has(key):
		var server := TextServerManager.get_primary_interface()
		var font := FontVariation.new()
		font.base_font = load(path)
		font.variation_opentype = {server.name_to_tag("wght"): weight}
		font.spacing_glyph = glyph
		font.spacing_bottom = line
		if tabular:
			font.opentype_features = {server.name_to_tag("tnum"): 1}
		_cache[key] = font
	return _cache[key]
