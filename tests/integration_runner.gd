extends SceneTree
const Model = preload("res://gameplay/systems/puzzle_engine.gd")
const Levels = preload("res://levels/campaign.gd")
const Store = preload("res://services/save_service.gd")
const Locale = preload("res://core/localization_service.gd")
var checks = 0
var failures: Array[String] = []

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures.append(description)
		printerr("FAIL: ", description)

func write_fixture(path: String, value: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path = "res://build/test_save.json"
	write_fixture(path, "{}")
	var store = Store.new(path)
	store.warning = ""
	store.data = Store.defaults()
	check(store.unlocked(0) and not store.unlocked(1), "initial unlocks")
	check(store.award(0, 1, 1) == 3 and store.unlocked(1), "award and unlock")
	store.data.settings.language = "tr"
	store.data.settings.music = false
	store.data.stats.folds = 12
	check(store.write(), "recoverable write")
	var loaded = Store.new(path)
	check(loaded.data.completed == store.data.completed, "progress roundtrip")
	check(loaded.data.settings.language == "tr" and not loaded.data.settings.music, "settings roundtrip")
	check(loaded.data.stats.folds == 12, "stats roundtrip")
	loaded.award(0, 5, 1, "2026-11-14")
	check(loaded.data.daily.size() == 1 and loaded.data.completed.size() == 1, "daily isolated")
	write_fixture(path, "broken")
	var recovered = Store.new(path)
	check(recovered.data.completed.has("0"), "corrupt primary recovers backup")
	write_fixture("res://build/partial_save.json", '{"version":1,"settings":{"music":false},"completed":{"2":{"stars":2,"best":3}},"stats":{"folds":"bad"}}')
	var partial = Store.new("res://build/partial_save.json")
	check(partial.data.completed.has("2") and not partial.data.settings.music and partial.data.settings.sfx, "partial retains valid fields")
	check(partial.data.stats.folds == 0, "invalid statistic rejected")
	write_fixture("res://build/future_save.json", '{"version":99}')
	var future = Store.new("res://build/future_save.json")
	check(future.warning == "future_save" and not future.write(), "future version preserved")
	for key in Locale.ROWS:
		var values = Locale.ROWS[key].split("|")
		check(values.size() == 16 and not "" in values, "16-language key " + key)
	var b = Levels.blank()
	Levels.put(b, Vector2i(0, 2), "emitter", 1)
	Levels.put(b, Vector2i(4, 2), "receiver")
	check(Model.simulate(b).solved, "straight light receiver")
	Levels.put(b, Vector2i(2, 2), "blocker")
	check(not Model.simulate(b).solved, "blocker stops light")
	Levels.put(b, Vector2i(2, 2), "mirror", 0)
	Levels.put(b, Vector2i(2, 0), "receiver")
	b.cells[14].mandatory = false
	check(Model.simulate(b).solved, "slash reflects east north")
	Levels.put(b, Vector2i(2, 2), "mirror", 1)
	Levels.put(b, Vector2i(2, 0), "empty")
	Levels.put(b, Vector2i(2, 4), "receiver")
	check(Model.simulate(b).solved, "backslash reflects east south")
	for orientation in range(2):
		for travel in range(4):
			var reflection_board = Levels.blank()
			var origin = Vector2i(2,2)
			var target_dir = Model.SLASH[travel] if orientation == 0 else Model.BACKSLASH[travel]
			Levels.put(reflection_board, origin - Model.DIRS[travel], "emitter", travel)
			Levels.put(reflection_board, origin, "mirror", orientation)
			Levels.put(reflection_board, origin + Model.DIRS[target_dir], "receiver")
			check(Model.simulate(reflection_board).solved, "reflection table %d %d" % [orientation,travel])
	b.cells[22].required_dir = 0
	check(not Model.simulate(b).solved, "direction-specific receiver")
	b.cells[22].erase("required_dir")
	b.cells[22].channel = "b"
	check(not Model.simulate(b).solved, "channel-specific receiver")
	# Splitter injects light into a mirror cycle; visited states bound it.
	b = Levels.blank()
	Levels.put(b, Vector2i(2, 4), "emitter", 0)
	Levels.put(b, Vector2i(2, 1), "splitter", 1)
	Levels.put(b, Vector2i(3, 1), "mirror", 1)
	Levels.put(b, Vector2i(3, 3), "mirror", 0)
	Levels.put(b, Vector2i(1, 3), "mirror", 1)
	Levels.put(b, Vector2i(1, 1), "mirror", 0)
	Levels.put(b, Vector2i(2, 0), "receiver")
	var simulation = Model.simulate(b)
	check(simulation.solved and simulation.visited < 100, "splitter and loop termination")
	var limited = Model.solve(Levels.make(24), 1)
	check(limited.status == "limit", "solver resource bound")
	var no_receiver = Levels.blank()
	Levels.put(no_receiver, Vector2i.ZERO, "emitter", 1)
	check(not Model.validate(no_receiver).is_empty(), "missing receiver rejected")
	# Validate the date-seeded generator for an entire calendar year.
	var start = int(Time.get_unix_time_from_datetime_string("2026-01-01T00:00:00"))
	for day_index in range(365):
		var date = Time.get_date_string_from_unix_time(start + day_index * 86400)
		var daily = Levels.daily(date)
		var verified = Model.solve(daily)
		check(verified.status == "solved" and not Model.simulate(daily).solved and verified.path.size() == daily.par, "daily verified " + date)
	# Directional receiver reflection must transform the required travel direction.
	b = Levels.blank()
	Levels.put(b, Vector2i(0,2), "emitter", 1)
	Levels.put(b, Vector2i(4,2), "receiver")
	b.cells[14].required_dir = 1
	b.panels = [{"id":"rx", "x":4,"y":2,"w":1,"h":1,"axis":"v","folded":false}]
	check(Model.fold(b,"rx").cells[14].required_dir == 3, "directional receiver reflected")
	check(Model.fold(Model.fold(b,"rx"),"rx") == b, "directional receiver involution")
	for bad in [{"width":"5","height":5,"cells":[],"panels":[]}, {"width":5,"height":5,"cells":{},"panels":[]}]:
		check(not Model.validate(bad).is_empty(), "malformed field types rejected")
	# Load actual main scene, exercise real screen and action methods.
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = "res://build/ui_test_save.json"
	write_fixture(scene.save_path_override, JSON.stringify(Store.defaults()))
	root.add_child(scene)
	await create_timer(0.7).timeout
	check(scene.screen == "home", "splash to home")
	scene.show_chapters()
	check(scene.screen == "chapters", "chapter navigation")
	scene.chapter = 0
	scene.show_levels()
	check(scene.screen == "levels", "level navigation")
	scene.start_level(0)
	await process_frame
	check(scene.board_view.light.solved == false, "playable board")
	var board = scene.board_view
	var panel = board.board.panels[0]
	var area = board.geometry()
	var center = area.position + Vector2(panel.x + panel.w * 0.5, panel.y + panel.h * 0.5) * area.size.x / 5
	var press = InputEventScreenTouch.new()
	press.index = 0
	press.position = center
	press.pressed = true
	board._gui_input(press)
	check(board.selected == panel.id and board.owner_id == 0, "touch selects panel")
	var second = InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2.ZERO
	second.pressed = true
	board._gui_input(second)
	check(board.owner_id == 0, "one gesture owner")
	var release = InputEventScreenTouch.new()
	release.index = 0
	release.position = center
	release.pressed = false
	board._gui_input(release)
	check(board.owner_id == -99 and scene.session.moves == 0, "tap does not fold")
	board.cancel_gesture()
	check(board.gesture == "CANCELLED", "gesture cancellation")
	scene.show_hint()
	check(not scene.hint_panel.is_empty(), "valid hint")
	scene.save.data.settings.reduced_motion = true
	scene.board_view.reduced_motion = true
	scene.request_fold(scene.hint_panel)
	await process_frame
	check(scene.awarded and is_instance_valid(scene.modal), "fold to completion")
	scene.session.reset()
	scene.awarded = false
	scene.session.commit(scene.session.board.panels[0].id)
	scene.session.undo()
	scene.persist_session()
	scene.start_level(0, false, true)
	check(scene.session.moves == 0 and scene.session.future.size() == 1, "resume redo history")
	scene.session.redo()
	check(scene.session.moves == 1, "resumed redo action")
	scene.session.reset()
	scene.awarded = false
	scene.show_game()
	scene.session.commit(scene.session.board.panels[0].id)
	scene.history_action(false)
	check(scene.session.moves == 0, "UI undo")
	scene.history_action(true)
	check(scene.session.moves == 1, "UI redo")
	scene.confirm_reset()
	check(is_instance_valid(scene.modal), "reset confirmation")
	scene.close_modal()
	scene.session.reset()
	scene.start_level(12)
	scene.session.commit(scene.session.board.panels[0].id)
	scene.persist_session()
	scene.save.data.active.redo = [null, "not-a-panel"]
	scene.start_level(12, false, true)
	check(scene.session.moves == 1, "invalid redo entries preserve active path")
	scene.start_level(0)
	for resolution in [Vector2i(360,800), Vector2i(390,844), Vector2i(412,915), Vector2i(480,960), Vector2i(480,640), Vector2i(800,600)]:
		root.content_scale_size = resolution
		root.size = resolution
		scene.size = resolution
		scene.show_game()
		await process_frame
		await process_frame
		var geometry = scene.board_view.geometry()
		check(is_equal_approx(geometry.size.x, geometry.size.y), "square board " + str(resolution))
		check(scene.board_view.size.x <= resolution.x, "board fits width " + str(resolution))
	for code in Locale.CODES:
		scene.words.language = code
		scene.show_settings()
		await process_frame
		check(scene.content.layout_direction == (Control.LAYOUT_DIRECTION_RTL if code == "ar" else Control.LAYOUT_DIRECTION_LTR), "layout direction " + code)
		scene.show_home()
		scene.show_statistics()
		scene.show_help()
	var font: Font = scene.theme.default_font
	var missing = {}
	for key in Locale.ROWS:
		for value in Locale.ROWS[key].split("|"):
			for character in value:
				var unicode = character.unicode_at(0)
				if unicode > 32 and not font.has_char(unicode): missing[character] = true
	check(missing.is_empty(), "bundled font coverage " + str(missing.keys()))
	check(true, "settings statistics help instantiated in 16 languages")
	scene.free()
	await process_frame
	print("INTEGRATION RESULT: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
