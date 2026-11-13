class_name PuzzleEngine
extends RefCounted
## Pure deterministic model. Direction denotes travel, not the edge entered.
## N,E,S,W = 0,1,2,3. / = [E,N,W,S], backslash = [W,S,E,N].
const DIRS = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SLASH = [1, 0, 3, 2]
const BACKSLASH = [3, 2, 1, 0]
const TYPES = ["empty", "mirror", "blocker", "receiver", "emitter", "splitter", "channel"]

static func cell(board: Dictionary, x: int, y: int) -> Dictionary:
	return board.cells[y * board.width + x]

static func validate(board: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not board.has_all(["width", "height", "cells", "panels"]):
		return ["Missing board fields"]
	if not board.width is int or not board.height is int or not board.cells is Array or not board.panels is Array:
		return ["Invalid board field types"]
	if board.width < 1 or board.width > 7 or board.height < 1 or board.height > 7:
		return ["Invalid dimensions"]
	if board.cells.size() != board.width * board.height:
		return ["Cell count does not match dimensions"]
	var emitters = 0
	var receivers = 0
	for c in board.cells:
		if not c is Dictionary or not c.has_all(["type", "dir"]) or c.type not in TYPES:
			errors.append("Invalid cell")
			continue
		if not c.dir is int or c.dir < 0 or c.dir > 3:
			errors.append("Invalid orientation")
		elif c.type == "mirror" and c.dir > 1:
			errors.append("Mirror orientation must be 0 or 1")
		if c.has("required_dir") and (not c.required_dir is int or c.required_dir < 0 or c.required_dir > 3):
			errors.append("Invalid receiver direction")
		if c.has("channel") and not c.channel is String: errors.append("Invalid channel")
		emitters += int(c.type == "emitter")
		receivers += int(c.type == "receiver")
	if emitters == 0 or receivers == 0:
		errors.append("Emitter and receiver required")
	var occupied = {}
	var ids = {}
	for p in board.panels:
		if not p is Dictionary or not p.has_all(["id", "x", "y", "w", "h", "axis", "folded"]):
			errors.append("Missing panel fields")
			continue
		if not p.id is String or p.id.is_empty() or not p.x is int or not p.y is int or not p.w is int or not p.h is int or not p.folded is bool:
			errors.append("Invalid panel field types")
			continue
		if ids.has(p.id):
			errors.append("Duplicate panel ID")
		ids[p.id] = true
		if p.axis not in ["v", "h"] or p.w < 1 or p.h < 1 or p.x < 0 or p.y < 0 or p.x + p.w > board.width or p.y + p.h > board.height:
			errors.append("Invalid panel bounds or axis")
			continue
		for y in range(p.y, p.y + p.h):
			for x in range(p.x, p.x + p.w):
				var key = y * board.width + x
				if occupied.has(key):
					errors.append("Overlapping panels")
				occupied[key] = true
	return errors

static func fold(board: Dictionary, panel_id: String) -> Dictionary:
	if not validate(board).is_empty():
		return board.duplicate(true)
	var result = board.duplicate(true)
	for p in board.panels:
		if p.id != panel_id:
			continue
		for ly in range(p.h):
			for lx in range(p.w):
				var c = cell(board, p.x + lx, p.y + ly).duplicate(true)
				var nx = p.w - 1 - lx if p.axis == "v" else lx
				var ny = p.h - 1 - ly if p.axis == "h" else ly
				if c.type == "mirror":
					c.dir = 1 - (c.dir % 2)
				elif c.type in ["emitter", "splitter", "channel", "receiver"]:
					c.dir = [0, 3, 2, 1][c.dir] if p.axis == "v" else [2, 1, 0, 3][c.dir]
				if c.has("required_dir"):
					c.required_dir = [0, 3, 2, 1][c.required_dir] if p.axis == "v" else [2, 1, 0, 3][c.required_dir]
				result.cells[(p.y + ny) * board.width + p.x + nx] = c
		for rp in result.panels:
			if rp.id == panel_id:
				rp.folded = not rp.get("folded", false)
		return result
	return result

static func canonical(board: Dictionary) -> String:
	var parts = PackedStringArray()
	for c in board.cells:
		parts.append("%s:%s:%s:%s:%s" % [c.type, c.dir, c.get("channel", "a"), c.get("required_dir", -1), c.get("mandatory", true)])
	return "|".join(parts)

static func simulate(board: Dictionary) -> Dictionary:
	var queue: Array = []
	var segments: Array = []
	var active = {}
	var visited = {}
	var required = 0
	for y in range(board.height):
		for x in range(board.width):
			var c = cell(board, x, y)
			if c.type == "emitter":
				queue.append([x, y, c.dir, c.get("channel", "a")])
			if c.type == "receiver" and c.get("mandatory", true):
				required += 1
	var head = 0
	while head < queue.size():
		var beam = queue[head]
		head += 1
		var x: int = beam[0]
		var y: int = beam[1]
		var d: int = beam[2]
		var channel: String = beam[3]
		var key = "%d,%d,%d,%s" % [x, y, d, channel]
		if visited.has(key):
			continue
		visited[key] = true
		var nx: int = x + DIRS[d].x
		var ny: int = y + DIRS[d].y
		if nx < 0 or ny < 0 or nx >= board.width or ny >= board.height:
			continue
		segments.append([Vector2(x, y), Vector2(nx, ny), channel])
		var c = cell(board, nx, ny)
		match c.type:
			"blocker", "emitter":
				continue
			"receiver":
				if c.get("channel", channel) == channel and c.get("required_dir", d) == d:
					active[ny * board.width + nx] = true
				continue
			"mirror":
				d = SLASH[d] if c.dir % 2 == 0 else BACKSLASH[d]
			"channel":
				if d % 2 != c.dir % 2:
					continue
			"splitter":
				if c.dir != d:
					queue.append([nx, ny, c.dir, channel])
		queue.append([nx, ny, d, channel])
	var lit_required = 0
	for idx in active:
		if board.cells[idx].get("mandatory", true):
			lit_required += 1
	return {"segments": segments, "active": active, "solved": required > 0 and lit_required == required, "visited": visited.size()}

static func solve(board: Dictionary, max_states: int = 8192) -> Dictionary:
	if not validate(board).is_empty():
		return {"status": "invalid", "path": [], "states": 0}
	var queue: Array = [[board, []]]
	var seen = {canonical(board): true}
	var head = 0
	while head < queue.size():
		var entry = queue[head]
		head += 1
		if simulate(entry[0]).solved:
			return {"status": "solved", "path": entry[1], "states": head}
		for p in board.panels:
			var next = fold(entry[0], p.id)
			var key = canonical(next)
			if not seen.has(key):
				if seen.size() >= max_states:
					return {"status": "limit", "path": [], "states": head}
				seen[key] = true
				queue.append([next, entry[1] + [p.id]])
	return {"status": "unsolvable", "path": [], "states": head}
