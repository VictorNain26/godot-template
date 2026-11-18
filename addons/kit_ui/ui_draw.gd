class_name UiDraw
extends RefCounted

## What every screen draws the same way: a line of text, a menu row, a key
## cap, a legend of keys, a slider, the name of the game. The values come
## from UiStyle. Part of the kit's menus (addons/kit_ui).

const LEFT := HORIZONTAL_ALIGNMENT_LEFT
const CENTER := HORIZONTAL_ALIGNMENT_CENTER
const RIGHT := HORIZONTAL_ALIGNMENT_RIGHT
## Height of a key cap, as a multiple of the size of its label.
const KEY_HEIGHT := 1.3
## A key drawn as an arrow, not as a letter.
const ARROWS := {"<": Vector2.LEFT, ">": Vector2.RIGHT, "^": Vector2.UP, "v": Vector2.DOWN}


## Draws `string` with `at` on its baseline, at its left, centre or right.
## Returns the width of the text.
static func text(
	canvas: CanvasItem,
	font: Font,
	at: Vector2,
	string: String,
	size: int,
	colour: Color,
	align: HorizontalAlignment = LEFT,
	outline: int = 0
) -> float:
	var width := font.get_string_size(string, LEFT, -1, size).x
	var from := at
	if align == CENTER:
		from.x -= width * 0.5
	elif align == RIGHT:
		from.x -= width
	if outline > 0:
		var edge := Color(UiStyle.INK, 0.85 * colour.a)
		canvas.draw_string_outline(font, from, string, LEFT, -1, size, outline, edge)
	canvas.draw_string(font, from, string, LEFT, -1, size, colour)
	return width


## The largest size up to `size` at which `string` is no wider than `width`.
static func fit(font: Font, string: String, size: int, width: float) -> int:
	var wide := font.get_string_size(string, LEFT, -1, size).x
	return size if wide <= width else maxi(floori(size * width / wide), 1)


## Baseline that centres one line of `font` at `size` in `rect`.
static func baseline(font: Font, size: int, rect: Rect2) -> float:
	var height := font.get_ascent(size) + font.get_descent(size)
	return rect.position.y + (rect.size.y - height) * 0.5 + font.get_ascent(size)


## An open arrow head pointing along `direction`.
static func chevron(
	canvas: CanvasItem, centre: Vector2, half: float, direction: Vector2, colour: Color
) -> void:
	var side := direction.orthogonal() * half
	var tip := centre + direction * half * 0.5
	var back := centre - direction * half * 0.5
	var points := PackedVector2Array([back + side, tip, back - side])
	canvas.draw_polyline(points, colour, maxf(half * 0.36, 2.0), true)


## A menu row: the plate of what is selected, then its label.
static func row(canvas: CanvasItem, rect: Rect2, label: String, focused: bool, size: int) -> void:
	if focused:
		canvas.draw_style_box(UiStyle.focus(), rect)
	var font := UiStyle.body(UiStyle.STRONG if focused else UiStyle.REGULAR)
	var colour := UiStyle.ACCENT_HOT if focused else Color(UiStyle.TEXT, UiStyle.SECONDARY)
	var at := Vector2(rect.position.x + UiStyle.UNIT * 2, baseline(font, size, rect))
	text(canvas, font, at, label, size, colour)


## A level out of `steps`, as blocks: lit ones are taller as well as brighter.
static func slider(canvas: CanvasItem, rect: Rect2, level: int, steps: int, lit: Color) -> void:
	var gap := 4.0
	var width := (rect.size.x - gap * (steps - 1)) / steps
	for i in steps:
		var on := i < level
		var tall := rect.size.y if on else rect.size.y * 0.4
		var block := Rect2(rect.position.x + i * (width + gap), rect.end.y - tall, width, tall)
		canvas.draw_rect(block, lit if on else Color(UiStyle.TEXT, 0.3))


static func keycap_width(label: String, size: int) -> float:
	var tall := roundf(size * KEY_HEIGHT)
	if ARROWS.has(label):
		return tall
	var wide := UiStyle.body(UiStyle.STRONG).get_string_size(label, LEFT, -1, size).x
	return maxf(tall, wide + roundf(size * 0.8))


## A key cap whose label sits on the baseline `at.y`, starting at `at.x`.
## Returns its width.
static func keycap(
	canvas: CanvasItem, at: Vector2, label: String, size: int, colour: Color
) -> float:
	var font := UiStyle.body(UiStyle.STRONG)
	var wide := keycap_width(label, size)
	var tall := roundf(size * KEY_HEIGHT)
	var middle := at.y - font.get_ascent(size) * 0.36
	var cap := Rect2(at.x, roundf(middle - tall * 0.5), wide, tall)
	canvas.draw_style_box(UiStyle.keycap(), cap)
	if ARROWS.has(label):
		var pointing: Vector2 = ARROWS[label]
		chevron(canvas, cap.get_center() - Vector2(0, 1), size * 0.3, pointing, colour)
	else:
		text(canvas, font, Vector2(cap.get_center().x, at.y - 1.0), label, size, colour, CENTER)
	return wide


## Size of a legend: `entries` are [label, [keys]] pairs, wrapped at `limit`.
static func legend_size(entries: Array, size: int, limit: float) -> Vector2:
	var lines := _legend_lines(entries, size, limit)
	var wide := 0.0
	for line: Array in lines:
		var line_width: float = line[0]
		wide = maxf(wide, line_width)
	return Vector2(wide, lines.size() * roundf(size * 2.0) - roundf(size * 0.5))


## Draws a legend of keys with its top at `at.y`, each line placed around
## `at.x` according to `align`, on a plate if it lies over the game. Returns
## the size it took, without the plate.
static func legend(
	canvas: CanvasItem,
	entries: Array,
	at: Vector2,
	size: int,
	limit: float,
	align: HorizontalAlignment = CENTER,
	plated: bool = false
) -> Vector2:
	var font := UiStyle.body()
	var lines := _legend_lines(entries, size, limit)
	var block := legend_size(entries, size, limit)
	if plated:
		var corner := Vector2(at.x, at.y)
		if align == CENTER:
			corner.x -= block.x * 0.5
		elif align == RIGHT:
			corner.x -= block.x
		var plate := Rect2(corner, block).grow_individual(
			UiStyle.UNIT * 2, UiStyle.UNIT, UiStyle.UNIT * 2, UiStyle.UNIT
		)
		canvas.draw_style_box(UiStyle.plate(), plate)
	var y := at.y + roundf(size * 1.12)
	for line: Array in lines:
		var x := at.x
		if align == CENTER:
			x -= line[0] * 0.5
		elif align == RIGHT:
			x -= line[0]
		for entry: Array in line[1]:
			for key: String in entry[1]:
				x += keycap(canvas, Vector2(x, y), key, size, UiStyle.TEXT) + 4.0
			x += roundf(size * 0.3)
			x += text(canvas, font, Vector2(x, y), str(entry[0]), size, UiStyle.TEXT)
			x += roundf(size * 1.4)
		y += roundf(size * 2.0)
	return block


## A paragraph wrapped at `width`, with LINE_HEIGHT between its lines and
## `at` at its top left. Returns its height.
static func paragraph(
	canvas: CanvasItem,
	at: Vector2,
	string: String,
	size: int,
	width: float,
	colour: Color,
	outline: int = 0
) -> float:
	var font := UiStyle.reading(size)
	var from := at + Vector2(0.0, font.get_ascent(size))
	if outline > 0:
		var edge := Color(UiStyle.INK, 0.85 * colour.a)
		canvas.draw_multiline_string_outline(
			font, from, string, LEFT, width, size, -1, outline, edge
		)
	canvas.draw_multiline_string(font, from, string, LEFT, width, size, -1, colour)
	return font.get_multiline_string_size(string, LEFT, width, size).y


## A panel of menu rows with its bottom right corner at `corner`: what the
## title screens draw. `extra` leaves room under the rows. Returns the panel.
static func menu(
	canvas: CanvasItem, corner: Vector2, labels: Array, index: int, size: int, extra: float = 0.0
) -> Rect2:
	var strong := UiStyle.body(UiStyle.STRONG)
	var wide := size * 10.0
	for label: String in labels:
		wide = maxf(wide, strong.get_string_size(label, LEFT, -1, size).x + UiStyle.UNIT * 6.0)
	var tall := size + UiStyle.ROW_PAD * 2.0
	var pitch := tall + UiStyle.UNIT * 0.5
	var pad := UiStyle.UNIT * 2.0
	var inner := Vector2(wide, labels.size() * pitch - UiStyle.UNIT * 0.5 + extra)
	var panel := Rect2(corner - inner - Vector2(pad, pad) * 2.0, inner + Vector2(pad, pad) * 2.0)
	canvas.draw_style_box(UiStyle.panel(), panel)
	for i in labels.size():
		var at := panel.position + Vector2(pad, pad + i * pitch)
		row(canvas, Rect2(at, Vector2(wide, tall)), str(labels[i]), i == index, size)
	return panel


## The rows of a menu drawn by `menu`: `panel` is what `menu` returned,
## `count` and `size` what it was given.
static func menu_rects(panel: Rect2, count: int, size: int) -> Array[Rect2]:
	var tall := size + UiStyle.ROW_PAD * 2.0
	var pitch := tall + UiStyle.UNIT * 0.5
	var pad := UiStyle.UNIT * 2.0
	var out: Array[Rect2] = []
	for i in count:
		var at := panel.position + Vector2(pad, pad + i * pitch)
		out.append(Rect2(at, Vector2(panel.size.x - pad * 2.0, tall)))
	return out


## The row of a menu drawn by `menu` that holds `point`, or -1.
static func menu_hit(panel: Rect2, count: int, size: int, point: Vector2) -> int:
	var rects := menu_rects(panel, count, size)
	for i in rects.size():
		if rects[i].has_point(point):
			return i
	return -1


## A panel of figures with its bottom right corner at `corner`: `rows` are
## [label, value] pairs, the labels on the left edge and the values on the
## right one, in figures of one width. `notes` are [text, colour] lines under
## a rule, wrapped to the width of the panel. Returns the panel.
static func stats(
	canvas: CanvasItem, corner: Vector2, rows: Array, size: int, notes: Array = []
) -> Rect2:
	var font := UiStyle.body()
	var figures := UiStyle.figures()
	var reading := UiStyle.reading(size)
	var pad := UiStyle.UNIT * 3.0
	var pitch := roundf(size * UiStyle.LINE_HEIGHT)
	var wide := size * 14.0
	for entry: Array in rows:
		var label := font.get_string_size(str(entry[0]), LEFT, -1, size).x
		var value := figures.get_string_size(str(entry[1]), LEFT, -1, size).x
		wide = maxf(wide, label + value + UiStyle.UNIT * 5.0)
	var gap := UiStyle.UNIT * 2.0 if not notes.is_empty() else 0.0
	var tall := rows.size() * pitch + gap
	for note: Array in notes:
		tall += reading.get_multiline_string_size(str(note[0]), LEFT, wide, size).y
	var inner := Vector2(wide, tall)
	var panel := Rect2(corner - inner - Vector2(pad, pad) * 2.0, inner + Vector2(pad, pad) * 2.0)
	canvas.draw_style_box(UiStyle.panel(), panel)
	var x := panel.position.x + pad
	var top := panel.position.y + pad
	var quiet := Color(UiStyle.TEXT, UiStyle.SECONDARY)
	for entry: Array in rows:
		var y := baseline(font, size, Rect2(x, top, wide, pitch))
		text(canvas, font, Vector2(x, y), str(entry[0]), size, quiet)
		text(canvas, figures, Vector2(x + wide, y), str(entry[1]), size, UiStyle.TEXT, RIGHT)
		top += pitch
	if not notes.is_empty():
		var rule := Rect2(x, top + gap * 0.5, wide, 1.0)
		canvas.draw_rect(rule, Color(UiStyle.EDGE, UiStyle.BORDER_ALPHA))
		top += gap
	for note: Array in notes:
		var tint: Color = note[1]
		top += paragraph(canvas, Vector2(x, top), str(note[0]), size, wide, tint)
	return panel


## The name of the game: letter-spaced capitals that glow like embers, each
## letter warming and cooling in turn. `at` is the left end of the baseline.
static func logo(canvas: CanvasItem, at: Vector2, title: String, time: float) -> void:
	var size := UiStyle.LOGO
	var font := UiStyle.display(size)
	var x := at.x
	for i in title.length():
		var letter := title[i]
		var pos := Vector2(x, at.y)
		for pass_index in 3:
			var glow := Color(UiStyle.ACCENT, 0.06)
			canvas.draw_string_outline(font, pos, letter, LEFT, -1, size, 8 + pass_index * 10, glow)
		canvas.draw_string_outline(font, pos, letter, LEFT, -1, size, 6, Color(UiStyle.INK, 0.9))
		x += font.get_string_size(letter, LEFT, -1, size).x
	x = at.x
	for i in title.length():
		var letter := title[i]
		var heat := 0.5 + 0.5 * sin(time * 1.1 + i * 0.7)
		var colour := UiStyle.ACCENT.lerp(UiStyle.ACCENT_HOT, heat)
		canvas.draw_string(font, Vector2(x, at.y), letter, LEFT, -1, size, colour)
		x += font.get_string_size(letter, LEFT, -1, size).x


## A veil of ink over `rect`, as dense at each corner as `alphas` says
## (top left, top right, bottom right, bottom left) and fading between them.
static func veil(canvas: CanvasItem, rect: Rect2, alphas: Array[float]) -> void:
	var corners := PackedVector2Array(
		[
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		]
	)
	var colours := PackedColorArray()
	for alpha in alphas:
		colours.append(Color(UiStyle.INK, alpha))
	canvas.draw_polygon(corners, colours)


static func _entry_width(entry: Array, size: int) -> float:
	var wide := UiStyle.body().get_string_size(str(entry[0]), LEFT, -1, size).x
	for key: String in entry[1]:
		wide += keycap_width(key, size) + 4.0
	return wide + roundf(size * 0.3)


## Lines of a legend as [width, [entries]], breaking where `limit` is passed.
static func _legend_lines(entries: Array, size: int, limit: float) -> Array:
	var gap := roundf(size * 1.4)
	var lines: Array = []
	var line: Array = []
	var wide := 0.0
	for entry: Array in entries:
		var w := _entry_width(entry, size)
		if not line.is_empty() and wide + gap + w > limit:
			lines.append([wide, line])
			line = []
			wide = 0.0
		wide += w if line.is_empty() else gap + w
		line.append(entry)
	if not line.is_empty():
		lines.append([wide, line])
	return lines
