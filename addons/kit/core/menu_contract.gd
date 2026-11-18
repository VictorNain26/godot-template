class_name MenuContract
extends RefCounted
## What every menu of a game offers, whoever drew it (the kit's menus in
## addons/kit_ui, or the game's own), so the kit can check it the same way:
## real keys, pad buttons, stick and pointer move through it and choose,
## its texts have their English, its text is big enough and stands out from
## what it lies on. The game lists its menus in its kit config's
## `static func menus() -> Array[Callable]` (each call builds one menu);
## tests/test_menu_contract.gd and MouseCheck.menus() check each.
##
## A menu node offers:
##   signal menu_chosen(index: int)   emitted when an item is chosen, by any means
##   var menu_dry_run: bool           true: choosing only emits menu_chosen, so
##                                    a check can choose "Quit" without quitting
##   func menu_open() -> void         shows the menu, ready for input
##   func menu_rects() -> Array[Rect2]    each item on screen, in the viewport's
##                                    coordinates, in the order up and down go
##   func menu_index() -> int         the item selected
##   func menu_texts() -> Array[String]   each item's text as written in the
##                                    code (French), before Loc.t
##   func menu_text_style() -> Dictionary  "size": the items' text size in
##                                    pixels at 100 %; "pairs": [text, under]
##                                    colours, everything the items' text is
##                                    shown on, blended as on screen
## Up and down move by one item; at an end they wrap or stay. Part of the kit
## (addons/kit).

## The smallest text size, in pixels at 100 % in a 1280×720 window (28 px in
## 1080p).
const TEXT_FLOOR := 19
## WCAG 2.2, 1.4.3: normal text against what it lies on.
const CONTRAST_MIN := 4.5
## WCAG 2.2, 2.5.8: a pointer target is at least 24 by 24 CSS pixels.
const TARGET_MIN := 24.0

const METHODS: Array[StringName] = [
	&"menu_open", &"menu_rects", &"menu_index", &"menu_texts", &"menu_text_style"
]


## What `menu` lacks of the contract, empty when it offers it all.
static func missing(menu: Object) -> Array[String]:
	var out: Array[String] = []
	for method in METHODS:
		if not menu.has_method(method):
			out.append("no %s()" % method)
	if not menu.has_signal(&"menu_chosen"):
		out.append("no signal menu_chosen")
	if not &"menu_dry_run" in menu:
		out.append("no var menu_dry_run")
	return out


## What is wrong with the items' layout: none, one off screen or smaller than
## a pointer target, two overlapping.
static func layout_problems(rects: Array[Rect2], screen: Rect2) -> Array[String]:
	var out: Array[String] = []
	if rects.is_empty():
		out.append("no item")
	for i in rects.size():
		var item := rects[i]
		if not screen.encloses(item):
			out.append("item %d is not wholly on screen" % i)
		if item.size.x < TARGET_MIN or item.size.y < TARGET_MIN:
			out.append("item %d is smaller than %d px" % [i, TARGET_MIN])
		for j in range(i + 1, rects.size()):
			if item.intersects(rects[j]):
				out.append("items %d and %d overlap" % [i, j])
	return out


## What is wrong with the items' text: too small, or too close in colour to
## what it lies on.
static func style_problems(style: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var size: int = style.get("size", 0)
	if size < TEXT_FLOOR:
		out.append("text of %d px, under %d" % [size, TEXT_FLOOR])
	var pairs: Array = style.get("pairs", [])
	if pairs.is_empty():
		out.append("no text colours given")
	for pair: Array in pairs:
		var text: Color = pair[0]
		var under: Color = pair[1]
		var ratio := contrast(text, under)
		if ratio < CONTRAST_MIN:
			out.append(
				"contrast %.2f:1 between %s and %s" % [ratio, text.to_html(), under.to_html()]
			)
	return out


## Where `index` goes after one step `by` (+1 down, -1 up) among `count`
## items: wrapping, or staying at an end. Both are allowed.
static func steps_to(index: int, by: int, count: int) -> Array[int]:
	var wrapped := posmod(index + by, count)
	var held := clampi(index + by, 0, count - 1)
	var out: Array[int] = [wrapped]
	if held != wrapped:
		out.append(held)
	return out


## WCAG contrast ratio between two colours, from 1 to 21.
static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Relative luminance: the weighted sum of the linearised channels.
static func luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b
