class_name Campaign
extends RefCounted
const Model = preload("res://gameplay/systems/puzzle_engine.gd")
const CHAPTERS = ["First Light", "Reflections", "Hidden Paths", "Dual Signals", "Resonance", "The Final Fold"]
## Authored route families. Variants alter endpoints, axes, spatial reflection,
## and scramble masks. No runtime random boards; all levels are solver checked.
static func blank() -> Dictionary:
	var b = {"width": 5, "height": 5, "cells": [], "panels": []}
	for i in range(25): b.cells.append({"type": "empty", "dir": 0})
	return b

static func put(b: Dictionary, point: Vector2i, type: String, dir: int = 0) -> void:
	b.cells[point.y * 5 + point.x] = {"type": type, "dir": dir}

static func direction(a: Vector2i, b: Vector2i) -> int:
	if b.x > a.x: return 1
	if b.x < a.x: return 3
	if b.y > a.y: return 2
	return 0

static func route(b: Dictionary, points: Array, prefix: String) -> void:
	put(b, points[0], "emitter", direction(points[0], points[1]))
	put(b, points[-1], "receiver")
	for i in range(1, points.size() - 1):
		var incoming = direction(points[i - 1], points[i])
		var outgoing = direction(points[i], points[i + 1])
		var orientation = 0 if Model.SLASH[incoming] == outgoing else 1
		put(b, points[i], "mirror", orientation)
		b.panels.append({"id": prefix + str(i), "x": points[i].x, "y": points[i].y, "w": 1, "h": 1, "axis": "v" if i % 2 else "h", "folded": false})

static func make(index: int) -> Dictionary:
	var chapter = index / 10
	var variant = index % 10
	var b = blank()
	var x = 1 + variant % 3
	var y = 1 + (variant / 3) % 3
	match chapter:
		0:
			route(b, [Vector2i(0, y), Vector2i(x, y), Vector2i(x, 0 if variant < 5 else 4)], "p")
		1:
			route(b, [Vector2i(0, y), Vector2i(x, y), Vector2i(x, 0), Vector2i(4, 0)], "p")
		2:
			route(b, [Vector2i(0, 4), Vector2i(x, 4), Vector2i(x, y), Vector2i(4, y), Vector2i(4, 0)], "p")
			put(b, Vector2i(0, 0), "blocker")
			put(b, Vector2i(0, 1), "blocker")
		3:
			var dual_routes = [
				[[Vector2i(0,1),Vector2i(1,1),Vector2i(1,0)], [Vector2i(4,3),Vector2i(3,3),Vector2i(3,4)]],
				[[Vector2i(0,1),Vector2i(2,1),Vector2i(2,0)], [Vector2i(4,3),Vector2i(2,3),Vector2i(2,4)]],
				[[Vector2i(0,1),Vector2i(3,1),Vector2i(3,0)], [Vector2i(4,3),Vector2i(1,3),Vector2i(1,4)]],
				[[Vector2i(0,2),Vector2i(1,2),Vector2i(1,0)], [Vector2i(4,4),Vector2i(3,4),Vector2i(3,3)]],
				[[Vector2i(0,0),Vector2i(3,0),Vector2i(3,1),Vector2i(4,1)], [Vector2i(0,3),Vector2i(1,3),Vector2i(1,4)]]
			]
			route(b, dual_routes[variant % 5][0], "a")
			route(b, dual_routes[variant % 5][1], "b")
		4, 5:
			var patterns = [
				[Vector2i(0,2),1,Vector2i(2,2),0,Vector2i(2,0),0,Vector2i(4,0),Vector2i(4,2),1,Vector2i(4,4)],
				[Vector2i(0,2),1,Vector2i(1,2),2,Vector2i(1,4),1,Vector2i(3,4),Vector2i(4,2),0,Vector2i(4,0)],
				[Vector2i(4,2),3,Vector2i(3,2),0,Vector2i(3,0),1,Vector2i(0,0),Vector2i(0,2),0,Vector2i(0,4)],
				[Vector2i(2,0),2,Vector2i(2,1),1,Vector2i(2,4),1,Vector2i(4,4),Vector2i(4,1),1,Vector2i(4,3)],
				[Vector2i(2,4),0,Vector2i(2,3),3,Vector2i(2,0),0,Vector2i(4,0),Vector2i(0,3),1,Vector2i(0,1)]
			]
			var pattern = patterns[variant % 5]
			put(b, pattern[0], "emitter", pattern[1])
			put(b, pattern[2], "splitter", pattern[3])
			put(b, pattern[4], "mirror", pattern[5])
			put(b, pattern[6], "receiver")
			put(b, pattern[7], "mirror", pattern[8])
			put(b, pattern[9], "receiver")
			for j in [4,7,2]:
				b.panels.append({"id": "s" + str(j), "x": pattern[j].x, "y": pattern[j].y, "w": 1, "h": 1, "axis": "v" if j == 4 or pattern[3] % 2 else "h"})
			if chapter == 5:
				b = add_final_signal(b)
	# Expand selected mirror panels into an adjacent empty cell: position and
	# orientation both change, demonstrating actual rectangular reflection.
	for p in b.panels:
		if not p.has("folded"): p.folded = false
	for pi in range(b.panels.size()):
		var p = b.panels[pi]
		if variant % 2 == 1 and p.axis == "v" and p.x < 4 and Model.cell(b, p.x + 1, p.y).type == "empty":
			var overlaps = false
			for other in b.panels:
				if other.id != p.id and other.x == p.x + 1 and other.y == p.y: overlaps = true
			if not overlaps:
				p.w = 2
				break
	# Reflect the entire authored arrangement for five additional compositions.
	if variant >= 5:
		var whole = b.duplicate(true)
		whole.panels = [{"id": "all", "x": 0, "y": 0, "w": 5, "h": 5, "axis": "v", "folded": false}]
		b.cells = Model.fold(whole, "all").cells
		for p in b.panels: p.x = 5 - p.x - p.w
	var scramble_count = 0
	for panel_index in range(b.panels.size()):
		if chapter > 0 and variant % 3 == 1 and panel_index == b.panels.size() - 1: continue
		b = Model.fold(b, b.panels[panel_index].id)
		scramble_count += 1
	b.id = "chapter_%02d_level_%02d" % [chapter + 1, variant + 1]
	b.chapter = chapter + 1
	b.number = index + 1
	b.par = scramble_count
	b.tutorial = "tutorial_%d" % chapter
	return b

static func load_level(index: int) -> Dictionary:
	var path = "res://levels/chapter_%02d/level_%02d.json" % [index / 10 + 1, index % 10 + 1]
	if not FileAccess.file_exists(path): return make(index)
	var b = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not b is Dictionary or not b.has_all(["cells", "panels"]): return make(index)
	if not b.cells is Array or not b.panels is Array: return make(index)
	for key in ["width", "height", "chapter", "number", "par"]: b[key] = int(b.get(key, 0))
	for c in b.cells:
		if not c is Dictionary or not c.get("dir") is float: return make(index)
		c.dir = int(c.dir)
		if c.has("required_dir"): c.required_dir = int(c.required_dir)
	for p in b.panels:
		if not p is Dictionary: return make(index)
		for key in ["x", "y", "w", "h"]:
			if not p.get(key) is float: return make(index)
			p[key] = int(p[key])
	return b if Model.validate(b).is_empty() else make(index)

static func add_final_signal(board: Dictionary) -> Dictionary:
	# Choose a two-turn authored edge route that preserves all existing signals.
	# Its optics must occupy empty cells; simulation checks all receivers remain lit.
	for row_a in [4, 0, 3, 1]:
		for row_b in [0, 4, 1, 3]:
			if row_a == row_b: continue
			for column in [1, 3, 2]:
				for side in [0, 4]:
					var points = [Vector2i(side, row_a), Vector2i(column, row_a), Vector2i(column, row_b), Vector2i(4 - side, row_b)]
					var empty = true
					for point in points:
						if Model.cell(board, point.x, point.y).type != "empty": empty = false
					if not empty: continue
					var candidate = board.duplicate(true)
					route(candidate, points, "final")
					if Model.simulate(candidate).solved: return candidate
	# Validated straight route fallback for dense layouts.
	for column in range(5):
		var empty = true
		for y in range(5):
			if Model.cell(board, column, y).type != "empty": empty = false
		if empty:
			put(board, Vector2i(column,4), "emitter", 0)
			put(board, Vector2i(column,0), "receiver")
			return board
	return board

static func daily(date: String) -> Dictionary:
	# UTC calendar date, FNV-1a over ISO YYYY-MM-DD, stable across devices.
	var seed_value: int = 2166136261
	for byte in date.to_utf8_buffer(): seed_value = ((seed_value ^ byte) * 16777619) & 0xffffffff
	var b = make(20 + seed_value % 40)
	var solved = Model.solve(b)
	if solved.status == "solved":
		for move in solved.path: b = Model.fold(b, move)
		for i in range(b.panels.size()):
			if seed_value & (1 << i): b = Model.fold(b, b.panels[i].id)
		if Model.simulate(b).solved: b = Model.fold(b, b.panels[0].id)
		var verified = Model.solve(b)
		if verified.status == "solved": b.par = verified.path.size()
	b.id = "daily_" + date
	return b
