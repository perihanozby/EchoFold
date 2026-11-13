extends SceneTree
const Model = preload("res://gameplay/systems/puzzle_engine.gd")
const Session = preload("res://gameplay/models/puzzle_session.gd")
const Levels = preload("res://levels/campaign.gd")
var checks = 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: ", description)

func _initialize() -> void:
	var b = Levels.make(1)
	check(Model.validate(b).is_empty(), "valid schema")
	for axis in ["v", "h"]:
		b.panels[0].axis = axis
		var twice = Model.fold(Model.fold(b, b.panels[0].id), b.panels[0].id)
		check(twice == b, "exact involution " + axis)
		var next = Model.fold(b, b.panels[0].id)
		for y in range(5):
			for x in range(5):
				var p = b.panels[0]
				if x < p.x or x >= p.x + p.w or y < p.y or y >= p.y + p.h:
					check(Model.cell(b, x, y) == Model.cell(next, x, y), "fold isolation")
	check(Model.fold(b, "invalid") == b, "invalid request unchanged")
	var invalid = b.duplicate(true)
	invalid.panels[0].x = -1
	check(not Model.validate(invalid).is_empty(), "invalid bounds detected")
	check(Model.fold(invalid, invalid.panels[0].id) == invalid, "invalid bounds unchanged")
	var session = Session.new(b)
	session.commit(b.panels[0].id)
	var committed = session.board.duplicate(true)
	check(session.moves == 1, "move count")
	check(session.undo() and session.board == b and session.moves == 0, "undo exact")
	check(session.redo() and session.board == committed and session.moves == 1, "redo exact")
	session.reset()
	check(session.board == b and session.future.is_empty(), "reset")
	for dir in range(4):
		check(Model.SLASH[Model.SLASH[dir]] == dir, "slash table involution")
		check(Model.BACKSLASH[Model.BACKSLASH[dir]] == dir, "backslash table involution")
	var reports = []
	var unique = {}
	var generate = "--generate" in OS.get_cmdline_user_args()
	for i in range(60):
		var level = Levels.make(i) if generate else Levels.load_level(i)
		var fingerprint = Model.canonical(level)
		check(not unique.has(fingerprint), "unique arrangement " + level.id)
		unique[fingerprint] = true
		check(Model.validate(level).is_empty(), "schema " + level.id)
		check(not Model.simulate(level).solved, "not initially won " + level.id)
		var solution = Model.solve(level)
		check(solution.status == "solved", "solvable " + level.id)
		if solution.status == "solved":
			level.par = solution.path.size()
			var solved = level
			for move in solution.path: solved = Model.fold(solved, move)
			check(Model.simulate(solved).solved, "verified solution " + level.id)
			check(Model.simulate(solved) == Model.simulate(solved), "deterministic " + level.id)
			check(level.par == solution.path.size(), "par equals shortest solution " + level.id)
			if generate:
				var directory = "res://levels/chapter_%02d" % [i / 10 + 1]
				DirAccess.make_dir_recursive_absolute(directory)
				var level_file = FileAccess.open(directory + "/level_%02d.json" % [i % 10 + 1], FileAccess.WRITE)
				level_file.store_string(JSON.stringify(level, "\t"))
				level_file.close()
			check(Levels.load_level(i) == level, "JSON level roundtrip " + level.id)
			reports.append({"id": level.id, "par": solution.path.size(), "solution": solution.path, "states": solution.states})
	var output = FileAccess.open("res://tests/verified_solutions.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(reports, "\t"))
	output.close()
	check(Levels.daily("2026-11-14") == Levels.daily("2026-11-14"), "deterministic daily")
	print("RESULT: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
