extends GdUnitTestSuite

## The rules any look of the menus keeps, whatever the game's skin sets in
## UiStyle: two faces with their licences, sizes in order and above a floor,
## text readable on its panel, a selection told by more than its colour.
## Part of the kit (addons/kit): a game that restyles its menus runs these
## against its own skin.

## A size on a 1280 by 720 screen that is 28 pixels on a 1080p one: the floor
## the Game Accessibility Guidelines give for text.
const FLOOR := 19
## WCAG AA for text.
const TEXT_MIN := 4.5
## Where a game keeps the scripts of its screens.
const SOURCES: Array[String] = ["res://src", "res://scenes", "res://scripts", "res://addons/kit"]


func test_two_typefaces_each_with_its_licence_beside_it() -> void:
	assert_object(load(UiStyle.DISPLAY_PATH)).is_instanceof(FontFile)
	assert_object(load(UiStyle.BODY_PATH)).is_instanceof(FontFile)
	assert_int(UiStyle.LICENCES.size()).is_greater_equal(1)
	for path: String in UiStyle.LICENCES:
		assert_bool(FileAccess.file_exists(path)).override_failure_message(path).is_true()


func test_a_text_that_names_no_font_gets_the_reading_face() -> void:
	# The project's custom font (gui/theme/custom_font) is the skin's reading face.
	assert_str(ThemeDB.fallback_font.get_font_name()).is_equal(UiStyle.body().get_font_name())
	assert_object(UiStyle.theme().default_font).is_same(UiStyle.body())


func test_the_type_scale_keeps_its_order_and_its_floor() -> void:
	var sizes: Array[int] = [
		UiStyle.LOGO,
		UiStyle.TITLE,
		UiStyle.HEADING,
		UiStyle.BANNER,
		UiStyle.MENU,
		UiStyle.BODY,
		UiStyle.SMALL
	]
	for i in sizes.size() - 1:
		assert_int(sizes[i]).is_greater(sizes[i + 1])
	assert_int(UiStyle.SMALL).is_greater_equal(FLOOR)
	assert_int(UiStyle.HUD).is_greater_equal(UiStyle.SMALL)
	# The order holds at every text size the options offer.
	for scale: float in Settings.TEXT_SCALES:
		assert_int(int(round(UiStyle.HEADING * scale))).is_greater(int(round(UiStyle.MENU * scale)))


func test_weights_figures_and_line_height_come_from_the_fonts() -> void:
	var regular := UiStyle.body().get_string_size("Reprendre", 0, -1, UiStyle.MENU).x
	var strong := UiStyle.body(UiStyle.STRONG).get_string_size("Reprendre", 0, -1, UiStyle.MENU).x
	assert_float(strong).is_greater_equal(regular)
	# A counter does not change width as it counts.
	var ones := UiStyle.figures().get_string_size("1:11.11", 0, -1, UiStyle.HUD).x
	var zeros := UiStyle.figures().get_string_size("0:00.00", 0, -1, UiStyle.HUD).x
	assert_float(ones).is_equal(zeros)
	for scale: float in Settings.TEXT_SCALES:
		var size := int(round(UiStyle.BODY * scale))
		var line := UiStyle.reading(size).get_height(size)
		assert_float(line).is_equal_approx(size * UiStyle.LINE_HEIGHT, 1.0)


func test_both_faces_hold_every_character_the_game_writes() -> void:
	var texts: Array = []
	var files: PackedStringArray = ProjectSettings.get_setting(
		"internationalization/locale/translations", PackedStringArray()
	)
	for path in files:
		var translation := load(path) as Translation
		for message in translation.get_message_list():
			texts.append(str(message))
			texts.append(str(translation.get_message(message)))
	# The no-break space French puts before a colon, and the quotes.
	texts.append(" «»’…")
	var body := UiStyle.body()
	var missing := {}
	for text: String in texts:
		for i in text.length():
			var code := text.unicode_at(i)
			if code > 32 and not body.has_char(code):
				missing[text[i]] = true
	assert_array(missing.keys()).is_empty()
	var display := UiStyle.display(UiStyle.HEADING)
	for code: int in "ABCDEFGHIJKLMNOPQRSTUVWXYZÀÂÇÉÈÊËÎÏÔÙÛÜ ".to_utf32_buffer().to_int32_array():
		assert_bool(display.has_char(code)).override_failure_message(char(code)).is_true()


func test_the_name_of_the_game_fits_between_the_margins() -> void:
	var title := str(ProjectSettings.get_setting("application/config/name")).to_upper()
	var width := UiStyle.display(UiStyle.LOGO).get_string_size(title, 0, -1, UiStyle.LOGO).x
	assert_float(width).is_less_equal(1280.0 - 2.0 * UiStyle.MARGIN)


func test_panels_keep_text_readable_over_anything() -> void:
	# The brightest and the darkest things a panel can lie on.
	for ground: Color in [Color.WHITE, Color.BLACK]:
		var under := UiStyle.over(UiStyle.INK, UiStyle.PANEL_ALPHA, ground)
		var quiet := UiStyle.over(UiStyle.TEXT, UiStyle.SECONDARY, under)
		assert_float(UiStyle.contrast(quiet, under)).is_greater_equal(TEXT_MIN)
		var plate := UiStyle.over(UiStyle.INK, UiStyle.PLATE_ALPHA, ground)
		assert_float(UiStyle.contrast(UiStyle.TEXT, plate)).is_greater_equal(TEXT_MIN)
		# What is selected differs from the rest by more than its colour.
		var lit := UiStyle.over(UiStyle.ACCENT, UiStyle.FOCUS_ALPHA, under)
		assert_float(UiStyle.contrast(UiStyle.ACCENT_HOT, lit)).is_greater_equal(TEXT_MIN)
	assert_int(UiStyle.focus().border_width_left).is_greater(0)


func _scripts(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		if sub != "tests":
			_scripts(dir.path_join(sub), out)


func test_no_screen_goes_round_the_style() -> void:
	var files: Array[String] = []
	for dir in SOURCES:
		_scripts(dir, files)
	assert_int(files.size()).is_greater(5)
	for file in files:
		# The build's self-test names the engine's font to check it is ours.
		if file.contains("/dev/"):
			continue
		var code := FileAccess.get_file_as_string(file)
		# The engine's own font, or a glyph used as a picture: a mark is drawn
		# (UiDraw.chevron, UiDraw.keycap), not typed.
		for banned: String in ["ThemeDB.fallback_font", "■", "▼", "›", "‹"]:
			(
				assert_bool(code.contains(banned))
				. override_failure_message("%s uses %s" % [file, banned])
				. is_false()
			)


func test_the_contrast_measure_matches_its_definition() -> void:
	assert_float(UiStyle.contrast(Color.BLACK, Color.WHITE)).is_equal_approx(21.0, 0.01)
	assert_float(UiStyle.contrast(Color.WHITE, Color.WHITE)).is_equal_approx(1.0, 0.001)
	# A published reference pair: #767676 on white is the lightest grey that passes AA.
	assert_float(UiStyle.contrast(Color("767676"), Color.WHITE)).is_between(4.5, 4.6)
	assert_object(UiStyle.over(Color.WHITE, 0.5, Color.BLACK)).is_equal(Color(0.5, 0.5, 0.5))
