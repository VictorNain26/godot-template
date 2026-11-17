extends GdUnitTestSuite

## The menus both games share: the options and keys pages, their rows, the
## legend of keys, and how a label and its value are written in each
## language. Part of the kit (addons/kit).


func after_test() -> void:
	Prefs.settings = Settings.new()
	Prefs.apply()


func _use(locale: String, scale: float = 1.0) -> void:
	Prefs.settings.locale = locale
	Prefs.settings.text_scale = scale
	Prefs.apply()
	Prefs.changed.emit()


func _menu() -> OptionsMenu:
	var menu: OptionsMenu = auto_free(OptionsMenu.new())
	add_child(menu)
	menu.open()
	return menu


func _settle() -> void:
	for i in 4:
		await get_tree().process_frame


func _rows(menu: OptionsMenu) -> Array[MenuRow]:
	var out: Array[MenuRow] = []
	for node in menu.find_children("*", "MenuRow", true, false):
		if (node as MenuRow).visible:
			out.append(node as MenuRow)
	return out


func test_french_never_lets_a_line_start_with_a_high_mark() -> void:
	_use("fr")
	assert_str(Loc.t("%s : %s") % ["Épée", "J"]).is_equal("Épée" + Loc.NBSP + ": J")
	assert_str(Loc.t("%d %%") % 100).is_equal("100" + Loc.NBSP + "%")
	assert_str(Loc.french_spaces("« Non ! » dit-il ; puis : quoi ?")).is_equal(
		"«~Non~!~» dit-il~; puis~: quoi~?".replace("~", Loc.NBSP)
	)
	# A text without those marks is shown exactly as written.
	assert_str(Loc.t("Reprendre")).is_equal("Reprendre")


func test_english_writes_a_value_and_a_percentage_its_own_way() -> void:
	_use("en")
	assert_str(Loc.t("%s : %s") % ["Sword", "J"]).is_equal("Sword: J")
	assert_str(Loc.t("%d %%") % 100).is_equal("100%")
	var menu := _menu()
	assert_str(menu.row_text(&"text")).is_equal("Text size: 100%")


func test_a_row_shows_its_label_and_its_value_in_two_columns() -> void:
	_use("fr")
	var menu := _menu()
	await _settle()
	var list := menu.rows()
	var rows := _rows(menu)
	assert_int(rows.size()).is_equal(list.size())
	for i in rows.size():
		assert_str(rows[i].label).is_equal(menu.row_label(list[i]))
		# A volume is drawn as a slider; any other value is written.
		if Settings.VOLUMES.has(list[i]):
			assert_int(rows[i].kind).is_equal(MenuRow.Kind.SLIDER)
			assert_int(rows[i].level).is_equal(Prefs.settings.volume(list[i]))
		elif rows[i].kind == MenuRow.Kind.VALUE:
			assert_str(rows[i].value).is_equal(menu.row_value(list[i]))
		# The one-line form says the same thing.
		assert_str(menu.row_text(list[i])).starts_with(rows[i].label)
		# Every row starts at the same left edge and ends at the same right edge.
		assert_float(rows[i].global_position.x).is_equal(rows[0].global_position.x)
		assert_float(rows[i].size.x).is_equal(rows[0].size.x)


func test_selecting_a_row_moves_nothing() -> void:
	_use("fr")
	var menu := _menu()
	await _settle()
	var panel: PanelContainer = menu.find_children("*", "PanelContainer", true, false)[0]
	var start: Array[Rect2] = [panel.get_global_rect()]
	for row in _rows(menu):
		start.append(row.get_global_rect())
	menu.move(1)
	await _settle()
	var moved: Array[Rect2] = [panel.get_global_rect()]
	for row in _rows(menu):
		moved.append(row.get_global_rect())
	assert_array(moved).is_equal(start)
	var rows := _rows(menu)
	assert_bool(rows[1].focused).is_true()
	assert_bool(rows[0].focused).is_false()


func test_the_page_fits_the_window_at_every_text_size_and_follows_the_selection() -> void:
	for locale: String in Settings.LOCALES:
		for scale: float in Settings.TEXT_SCALES:
			_use(locale, scale)
			var menu := _menu()
			for page in 2:
				await _settle()
				var window := menu.get_viewport_rect()
				var panel: PanelContainer = (
					menu.find_children("*", "PanelContainer", true, false)[0]
				)
				(
					assert_bool(
						window.grow(-UiStyle.MARGIN + 1.0).encloses(panel.get_global_rect())
					)
					. override_failure_message(
						"%s %s page %d: %s" % [locale, scale, page, panel.get_global_rect()]
					)
					. is_true()
				)
				# The last row is reached by scrolling, never lost.
				menu.move(-1)
				await _settle()
				var scroll: ScrollContainer = (
					menu.find_children("*", "ScrollContainer", true, false)[0]
				)
				var last := _rows(menu)[-1]
				assert_bool(last.focused).is_true()
				(
					assert_bool(scroll.get_global_rect().grow(1.0).encloses(last.get_global_rect()))
					. override_failure_message(
						"%s %s page %d: last row hidden" % [locale, scale, page]
					)
					. is_true()
				)
				menu.index = menu.rows().find(&"keys")
				menu.accept()
			menu.queue_free()
			await get_tree().process_frame


func test_the_legend_names_the_players_own_keys() -> void:
	_use("fr")
	var help := Prefs.help()
	assert_int(help.size()).is_equal(Prefs.help_entries.size())
	for i in help.size():
		assert_str(str(help[i][0])).is_equal(Loc.t(str(Prefs.help_entries[i][0])))
		var actions: Array = Prefs.help_entries[i][1]
		for k in actions.size():
			var action: StringName = actions[k]
			assert_str(str(help[i][1][k])).is_equal(Prefs.key_label(action))
	var bar: LegendBar = auto_free(LegendBar.new())
	add_child(bar)
	bar.show_entries(help)
	var one_line := bar.get_minimum_size()
	# Too long for its room, a legend wraps instead of leaving the screen.
	bar.limit = one_line.x * 0.6
	bar.show_entries(help)
	assert_float(bar.get_minimum_size().x).is_less_equal(one_line.x * 0.6)
	assert_float(bar.get_minimum_size().y).is_greater(one_line.y)


## Runs `paint` inside the draw of a control, where drawing is allowed.
func _paint(paint: Callable) -> void:
	var canvas: Control = auto_free(Control.new())
	canvas.draw.connect(paint.bind(canvas))
	add_child(canvas)
	await _settle()


func test_a_panel_of_figures_keeps_its_place_while_they_count() -> void:
	_use("fr")
	var corner := Vector2(1232.0, 600.0)
	var size := UiStyle.BODY
	var panels: Array[Rect2] = []
	for time: String in ["0:00.00", "0:32.45", "1:11.11"]:
		var figures := [["Temps", time], ["Pièces", "44 / 75"]]
		await _paint(
			func(c: Control) -> void: panels.append(UiDraw.stats(c, corner, figures, size))
		)
	assert_int(panels.size()).is_greater_equal(3)
	for panel in panels:
		assert_that(panel).is_equal(panels[0])
		assert_that(panel.end).is_equal(corner)
	# A long note wraps inside the panel: it grows down, never sideways.
	var note := "Il reste des secrets dans ce niveau. Une clé ouvre la dernière porte."
	var rows := [["Temps", "0:32.45"], ["Pièces", "44 / 75"]]
	var noted: Array[Rect2] = []
	await _paint(
		func(c: Control) -> void:
			noted.append(UiDraw.stats(c, corner, rows, size, [[note, UiStyle.ACCENT]]))
	)
	assert_float(noted[0].size.x).is_equal(panels[0].size.x)
	assert_float(noted[0].size.y).is_greater(panels[0].size.y + size * 2.0)


func test_a_headline_too_long_for_the_screen_is_made_to_fit() -> void:
	var room := 1280.0 - UiStyle.MARGIN * 2.0
	for scale: float in Settings.TEXT_SCALES:
		var asked := roundi(UiStyle.TITLE * scale)
		var font := UiStyle.display(asked)
		var size := UiDraw.fit(font, "LA NUIT RECULE DE NOUVEAU", asked, room)
		var wide := (
			UiStyle
			. display(size)
			. get_string_size("LA NUIT RECULE DE NOUVEAU", UiDraw.LEFT, -1, size)
			. x
		)
		assert_float(wide).is_less_equal(room + 8.0)
		# Made smaller, it is still larger than what is read under it.
		assert_int(size).is_greater(roundi(UiStyle.BODY * scale))
		assert_int(UiDraw.fit(font, "FIN", asked, room)).is_equal(asked)


func test_the_pointer_selects_a_row_and_a_click_uses_it() -> void:
	# Without a window the engine gives the mouse to no Control: the rows'
	# own signals stand in for it here, and the mouse check scene (README)
	# sends real mouse events under Xvfb.
	var menu := _menu()
	await _settle()
	var rows := _rows(menu)
	rows[2].pointed.emit()
	assert_int(menu.index).is_equal(2)
	# A click on the right half of a volume raises it, on the left half lowers it.
	var master := Prefs.settings.volume(&"master")
	var row := rows[0]
	row.clicked.emit(row.side(row.value_span.y - 4.0))
	assert_int(menu.index).is_equal(0)
	assert_int(Prefs.settings.volume(&"master")).is_equal(master + 1)
	row.clicked.emit(row.side(row.value_span.x + 4.0))
	row.clicked.emit(row.side(row.value_span.x + 4.0))
	assert_int(Prefs.settings.volume(&"master")).is_equal(master - 1)
	# The label of a value is not a way to lower it.
	assert_int(row.side(UiStyle.UNIT * 3.0)).is_equal(1)
	# A click on a row that only does something does it: the page of keys.
	rows[OptionsMenu.MAIN.find(&"keys")].clicked.emit(1)
	assert_bool(menu.on_keys).is_true()
	# While a key is awaited, a click gives up instead of choosing.
	await _settle()
	rows = _rows(menu)
	rows[0].clicked.emit(1)
	assert_bool(menu.listening).is_true()
	rows[3].clicked.emit(1)
	assert_bool(menu.listening).is_false()
	assert_bool(menu.on_keys).is_true()
