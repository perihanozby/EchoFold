extends Control
const Model = preload("res://gameplay/systems/puzzle_engine.gd")
const Session = preload("res://gameplay/models/puzzle_session.gd")
const Levels = preload("res://levels/campaign.gd")
const Store = preload("res://services/save_service.gd")
const Locale = preload("res://core/localization_service.gd")
const Tokens = preload("res://ui/theme/design_tokens.gd")
const Board = preload("res://gameplay/rendering/board_view.gd")
const Audio = preload("res://services/audio_service.gd")
var save: RefCounted
var words = Locale.new()
var audio: Node
var content: VBoxContainer
var margin: MarginContainer
var screen = "splash"
var chapter = 0
var index = 0
var daily_id = ""
var session: RefCounted
var board_view: Control
var moves_label: Label
var instruction: Label
var undo_button: Button
var redo_button: Button
var fold_button: Button
var awarded = false
var current_stars = 0
var modal: Control
var save_elapsed = 0.0
var paused = false
var settings_return = "home"
var hint_panel = ""
var solutions: Array = []
var save_path_override = ""
var tutorial_stage = -1

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	theme = Tokens.theme()
	var save_path = "res://build/desktop_save.json" if OS.has_feature("editor") else "user://echofold.json"
	save = Store.new(save_path if save_path_override.is_empty() else save_path_override)
	words.language = save.data.settings.language if save.data.settings.language in Locale.CODES else "en"
	audio = Audio.new()
	add_child(audio)
	audio.settings(save.data.settings)
	if FileAccess.file_exists("res://levels/campaign_manifest.json"):
		solutions = JSON.parse_string(FileAccess.get_file_as_string("res://levels/campaign_manifest.json"))
	margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	resized.connect(_safe_area)
	_safe_area()
	show_splash()

func _safe_area() -> void:
	if not is_instance_valid(margin): return
	var top = 22
	var bottom = 20
	if OS.get_name() == "Android":
		var safe = DisplayServer.get_display_safe_area()
		var display = DisplayServer.screen_get_size()
		if display.y > 0:
			top += int(safe.position.y * size.y / display.y)
			bottom += int((display.y - safe.end.y) * size.y / display.y)
	margin.add_theme_constant_override("margin_left", maxi(16, int((size.x - 560) / 2)))
	margin.add_theme_constant_override("margin_right", maxi(16, int((size.x - 560) / 2)))
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)

func _process(delta: float) -> void:
	if screen == "game" and not paused and not awarded:
		save.data.stats.seconds += delta
		save_elapsed += delta
		if save_elapsed > 15:
			persist_session()
			save_elapsed = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_instance_valid(board_view): board_view.cancel_gesture()
		if save != null: persist_session()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save != null: persist_session()
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back()
		get_viewport().set_input_as_handled()

func t(key: String) -> String: return words.text(key)
func n(value: int) -> String: return words.number(value)

func clear(next_screen: String, scroll: bool = true) -> void:
	close_modal()
	for child in margin.get_children():
		margin.remove_child(child)
		child.queue_free()
	board_view = null
	screen = next_screen
	paused = false
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	content.layout_direction = Control.LAYOUT_DIRECTION_RTL if words.language == "ar" else Control.LAYOUT_DIRECTION_LTR
	if scroll:
		var scroller = ScrollContainer.new()
		scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		margin.add_child(scroller)
		scroller.add_child(content)
	else: margin.add_child(content)
	if not save.data.settings.reduced_motion:
		content.modulate.a = 0
		create_tween().tween_property(content, "modulate:a", 1, 0.2)

func label(text_value: String, font_size: int = 16, parent: Node = null) -> Label:
	var node = Label.new()
	node.text = text_value
	node.add_theme_font_size_override("font_size", font_size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else content).add_child(node)
	return node

func button(key: String, action: Callable, parent: Node = null, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = t(key)
	node.custom_minimum_size.y = 50
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		node.add_theme_stylebox_override("normal", Tokens.box(Color("284356"), Tokens.ACCENT))
		node.add_theme_color_override("font_color", Tokens.ACCENT)
	node.pressed.connect(func(): audio.play("tap"); action.call())
	node.button_down.connect(func():
		if not save.data.settings.reduced_motion:
			node.pivot_offset = node.size / 2
			create_tween().tween_property(node, "scale", Vector2.ONE * 0.975, 0.08))
	node.button_up.connect(func():
		if is_instance_valid(node): create_tween().tween_property(node, "scale", Vector2.ONE, 0.08))
	(parent if parent != null else content).add_child(node)
	return node

func row(parent: Node = null) -> HBoxContainer:
	var node = HBoxContainer.new()
	(parent if parent != null else content).add_child(node)
	return node

func header(key: String, back: Callable) -> void:
	var bar = row()
	var b = button("back", back, bar)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label(t(key), 26, bar)

func brand(parent: Node = null) -> void:
	var holder = VBoxContainer.new()
	(parent if parent != null else content).add_child(holder)
	var icon = TextureRect.new()
	icon.texture = load("res://assets/icons/echofold.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(112, 140)
	holder.add_child(icon)
	label("E C H O F O L D", 30, holder).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle = label(t("tagline"), 15, holder)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Tokens.SECONDARY)

func show_splash() -> void:
	clear("splash", false)
	var space = Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(space)
	brand()
	var bottom = Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom)
	await get_tree().create_timer(0.45).timeout
	if screen == "splash": show_home()

func show_home() -> void:
	if is_instance_valid(board_view) and board_view.busy: return
	persist_session()
	clear("home")
	brand()
	label("", 12)
	button("continue", func(): start_level(int(save.data.current), false, true), null, true)
	button("chapters", show_chapters)
	button("daily", func(): start_level(0, true, true))
	var bar = row()
	button("statistics", show_statistics, bar)
	button("settings", func(): settings_return = "home"; show_settings(), bar)
	button("help", show_help)
	label("◇   " + n(save.data.completed.size()) + " / " + n(60), 15).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if save.warning != "": label(t("save_warning"), 13)

func show_chapters() -> void:
	clear("chapters")
	header("chapters", show_home)
	for c in range(6):
		var count = 0
		for i in range(c * 10, c * 10 + 10): count += int(save.data.completed.has(str(i)))
		var chapter_index = c
		var b = button("chapter_" + str(c + 1), func(): chapter = chapter_index; show_levels())
		b.text = "%s   %s\n%s / %s   %s" % [n(c + 1).pad_zeros(2), t("chapter_" + str(c + 1)), n(count), n(10), "✓" if count == 10 else ("◇" if save.unlocked(c * 10) else "⌑")]
		b.custom_minimum_size.y = 98
		b.disabled = not save.unlocked(c * 10)
		if b.disabled: label(t("locked"), 13)

func show_levels() -> void:
	persist_session()
	clear("levels")
	header("levels", show_chapters)
	label(t("chapter_" + str(chapter + 1)), 23)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for i in range(chapter * 10, chapter * 10 + 10):
		var level_index = i
		var record = save.data.completed.get(str(i), {})
		var b = button("levels", func(): start_level(level_index), grid)
		b.text = n(i + 1).pad_zeros(2) + "\n" + ("★".repeat(int(record.get("stars", 0))) if not record.is_empty() else "◇")
		b.custom_minimum_size = Vector2(125, 98)
		b.disabled = not save.unlocked(i)

func start_level(level_index: int, daily: bool = false, restore: bool = false) -> void:
	index = clampi(level_index, 0, 59)
	daily_id = Time.get_date_string_from_system(true) if daily else ""
	var level = Levels.daily(daily_id) if daily else Levels.load_level(index)
	var solution = Model.solve(level)
	if solution.status != "solved":
		# Verified fallback, never display an unvalidated daily board.
		level = Levels.make(0)
		level.id = "daily_" + daily_id
		solution = Model.solve(level)
	level.par = solution.path.size()
	session = Session.new(level)
	if restore:
		var active = save.data.active
		if active.get("id", "") == level.id and active.get("path") is Array:
			# Replay only legal actions; never deserialize an authoritative board.
			for panel in active.path:
				if panel is String: session.commit(panel)
			if active.get("redo") is Array:
				var restored_redo = 0
				for panel in active.redo:
					if panel is String and session.commit(panel): restored_redo += 1
				for redo_index in range(restored_redo): session.undo()
	awarded = false
	hint_panel = ""
	tutorial_stage = 0 if daily_id.is_empty() and index % 10 == 0 else -1
	if daily_id.is_empty(): save.data.current = index
	show_game()

func show_game() -> void:
	clear("game")
	var bar = row()
	button("home", show_home, bar)
	button("pause", show_pause, bar)
	label(t("daily") if not daily_id.is_empty() else t("chapter_" + str(session.initial.chapter)), 15)
	label(words.date(daily_id) if not daily_id.is_empty() else "%s  %s" % [t("levels"), n(index + 1).pad_zeros(2)], 28)
	moves_label = label("", 16)
	board_view = Board.new()
	board_view.custom_minimum_size = Vector2(260, minf(360, size.x - 32))
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.reduced_motion = save.data.settings.reduced_motion
	board_view.effects = save.data.settings.effects
	content.add_child(board_view)
	board_view.set_board(session.board)
	board_view.panel_selected.connect(func(_id):
		audio.play("select")
		fold_button.disabled = false
		if tutorial_stage == 0:
			tutorial_stage = 1
			instruction.text = t("fold"))
	board_view.fold_requested.connect(request_fold)
	board_view.invalid_fold.connect(func(): audio.play("invalid"))
	instruction = label(t("tutorial_" + str(index / 10)) + "\n" + t("select") if tutorial_stage == 0 else t("select"), 14)
	instruction.custom_minimum_size.y = 40
	fold_button = button("fold", func(): request_fold(board_view.selected), null, true)
	fold_button.disabled = true
	var tools = row()
	undo_button = button("undo", func(): history_action(false), tools)
	redo_button = button("redo", func(): history_action(true), tools)
	var tools2 = row()
	button("reset", confirm_reset, tools2)
	button("hint", show_hint, tools2)
	refresh_board()
	if Model.simulate(session.board).solved and not awarded: complete_level()

func refresh_board() -> void:
	if not is_instance_valid(board_view): return
	board_view.set_board(session.board)
	moves_label.text = "%s  %s     /     %s  %s     ◇ %s" % [t("moves"), n(session.moves), t("par"), n(session.initial.par), n(board_view.light.active.size())]
	undo_button.disabled = session.history.is_empty()
	redo_button.disabled = session.future.is_empty()

func request_fold(id: String) -> void:
	if id.is_empty() or awarded or board_view.busy: return
	undo_button.disabled = true
	redo_button.disabled = true
	fold_button.disabled = true
	audio.play("fold")
	if save.data.settings.haptics and OS.get_name() == "Android": Input.vibrate_handheld(16)
	await board_view.animate_fold(id, func():
		var before = Model.simulate(session.board).active.size()
		if session.commit(id): save.data.stats.folds += 1
		if Model.simulate(session.board).active.size() > before: audio.play("receiver")
		refresh_board())
	if not is_instance_valid(board_view): return
	fold_button.disabled = false
	if tutorial_stage == 1:
		tutorial_stage = 2
		instruction.text = t("tutorial_" + str(index / 10))
	persist_session()
	if Model.simulate(session.board).solved: complete_level()

func history_action(redo: bool) -> void:
	if awarded or board_view.busy: return
	if redo: session.redo()
	else: session.undo()
	refresh_board()
	persist_session()

func show_hint() -> void:
	if awarded or board_view.busy: return
	var solution = Model.solve(session.board)
	if solution.status == "solved" and not solution.path.is_empty():
		hint_panel = solution.path[0]
		board_view.selected = hint_panel
		board_view.queue_redraw()
		fold_button.disabled = false
		instruction.text = t("hint") + " · " + t("fold")
		save.data.stats.hints += 1
		audio.play("hint")
		persist_session()

func make_modal() -> VBoxContainer:
	close_modal()
	paused = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	if not save.data.settings.reduced_motion:
		modal.modulate.a = 0
		create_tween().tween_property(modal, "modulate:a", 1, 0.2)
	var shade = ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = minf(390, size.x - 40)
	center.add_child(panel)
	var scroller = ScrollContainer.new()
	scroller.custom_minimum_size = Vector2(minf(350, size.x - 70), minf(570, size.y - 100))
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroller)
	var stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(stack)
	return stack

func close_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
	paused = false

func show_pause() -> void:
	if is_instance_valid(board_view) and board_view.busy: return
	persist_session()
	var stack = make_modal()
	label(t("pause"), 26, stack)
	button("resume", close_modal, stack, true)
	button("reset", confirm_reset, stack)
	button("settings", func(): settings_return = "game"; show_settings(), stack)
	button("levels", func(): chapter = index / 10; show_levels(), stack)
	button("home", show_home, stack)

func confirm_reset() -> void:
	if is_instance_valid(board_view) and board_view.busy: return
	var stack = make_modal()
	label(t("confirm"), 22, stack)
	button("reset", func(): session.reset(); awarded = false; persist_session(); show_game(), stack, true)
	button("cancel", close_modal, stack)

func complete_level() -> void:
	if awarded: return
	awarded = true
	current_stars = save.award(index, session.moves, session.initial.par, daily_id)
	audio.play("complete")
	if daily_id.is_empty() and index % 10 == 9 and index < 59: audio.play("unlock")
	var stack = make_modal()
	label(t("complete"), 28, stack)
	var stars = label("★ ".repeat(current_stars), 38, stack)
	if not save.data.settings.reduced_motion:
		stars.modulate.a = 0
		create_tween().tween_property(stars, "modulate:a", 1, 0.6)
	stars.add_theme_color_override("font_color", Tokens.WARM)
	label(t("moves") + "  " + n(session.moves), 18, stack)
	if daily_id.is_empty() and index % 10 == 9 and index < 59:
		label(t("unlocked") + " · " + t("chapter_" + str(index / 10 + 2)), 19, stack)
	var records: Dictionary = save.data.completed if daily_id.is_empty() else save.data.daily
	label(t("best") + "  " + n(records[str(index) if daily_id.is_empty() else daily_id].best), 16, stack)
	if daily_id.is_empty() and index < 59:
		button("next", func(): start_level(index + 1), stack, true)
	button("reset", func(): session.reset(); awarded = false; show_game(), stack)
	button("levels", func(): chapter = index / 10; show_levels(), stack)
	button("home", show_home, stack)

func show_settings() -> void:
	persist_session()
	clear("settings")
	header("settings", leave_settings)
	label(t("language"), 16)
	var picker = OptionButton.new()
	picker.custom_minimum_size.y = 50
	for name_value in Locale.NAMES: picker.add_item(name_value)
	picker.select(maxi(0, Locale.CODES.find(words.language)))
	content.add_child(picker)
	picker.item_selected.connect(func(selected_index): words.language = Locale.CODES[selected_index]; save.data.settings.language = words.language; save.write(); show_settings())
	for key in ["music", "sfx", "haptics", "reduced_motion"]:
		var setting_key = key
		var toggle = CheckButton.new()
		toggle.text = t(key)
		toggle.custom_minimum_size.y = 50
		toggle.button_pressed = save.data.settings[key]
		content.add_child(toggle)
		toggle.toggled.connect(func(value): save.data.settings[setting_key] = value; audio.settings(save.data.settings); save.write())
	label(t("effects"))
	var slider = HSlider.new()
	slider.custom_minimum_size.y = 48
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = save.data.settings.effects
	content.add_child(slider)
	slider.value_changed.connect(func(value): save.data.settings.effects = value; save.write())
	label(t("privacy"), 14)
	label(t("credits"), 13)
	button("licenses", show_licenses)

func show_licenses() -> void:
	clear("licenses")
	header("licenses", show_settings)
	for path in ["res://assets/licenses/Godot.txt", "res://assets/licenses/Engine-third-party.txt", "res://assets/fonts/OFL.txt", "res://assets/fonts/OFL-CJK.txt"]:
		if FileAccess.file_exists(path): label(FileAccess.get_file_as_string(path), 13)

func leave_settings() -> void:
	if settings_return == "game" and session != null: show_game()
	else: show_home()

func show_statistics() -> void:
	clear("statistics")
	header("statistics", show_home)
	var total_stars = 0
	for record in save.data.completed.values(): total_stars += record.stars
	for pair in [["levels", save.data.completed.size()], ["stars", total_stars], ["moves", int(save.data.stats.folds)], ["solved", int(save.data.stats.solves)], ["daily", save.data.daily.size()], ["hint", int(save.data.stats.hints)], ["time", int(save.data.stats.seconds / 60)]]:
		var card = PanelContainer.new()
		content.add_child(card)
		label(t(pair[0]) + "   " + n(pair[1]), 19, card)
	var best_chapter = 0
	for c in range(6):
		for level_index in range(c * 10, c * 10 + 10):
			if save.data.completed.has(str(level_index)): best_chapter = c
	var count = 0
	for level_index in range(best_chapter * 10, best_chapter * 10 + 10): count += int(save.data.completed.has(str(level_index)))
	label(t("chapter_" + str(best_chapter + 1)) + "   " + n(count) + " / " + n(10), 19)

func show_help() -> void:
	clear("help")
	header("help", show_home)
	brand()
	label(t("help_body"), 19)

func go_back() -> void:
	if is_instance_valid(board_view) and board_view.busy: return
	if is_instance_valid(modal):
		if awarded: show_home()
		else: close_modal()
		return
	match screen:
		"game": show_pause()
		"settings": leave_settings()
		"licenses": show_settings()
		"levels": show_chapters()
		"home":
			persist_session()
			if OS.get_name() == "Android": get_tree().quit()
		_: show_home()

func persist_session() -> void:
	if save == null: return
	if session != null and not awarded:
		var redo = session.redo_actions.duplicate()
		redo.reverse()
		save.data.active = {"id": session.initial.id, "path": session.actions.duplicate(), "redo": redo}
	save.write()
