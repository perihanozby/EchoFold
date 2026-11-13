extends Control
const Model = preload("res://gameplay/systems/puzzle_engine.gd")
signal panel_selected(id: String)
signal fold_requested(id: String)
signal invalid_fold
var board: Dictionary = {}
var light: Dictionary = {}
var selected = ""
var busy = false
var reduced_motion = false
var effects = 0.65
var animation_panel = ""
var flip = 0.0
var owner_id = -99
var press_position = Vector2.ZERO
var gesture = "IDLE"
var beam_alpha = 1.0
var selected_strength = 1.0
var beam_tween: Tween
var selection_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func geometry() -> Rect2:
	var side = minf(size.x, size.y) - 24
	return Rect2((size - Vector2.ONE * side) / 2, Vector2.ONE * side)

func set_board(value: Dictionary) -> void:
	board = value
	light = Model.simulate(board)
	if is_inside_tree() and not reduced_motion:
		if beam_tween: beam_tween.kill()
		beam_alpha = 0.2
		beam_tween = create_tween()
		beam_tween.tween_method(func(v: float): beam_alpha = v; queue_redraw(), 0.2, 1.0, 0.22)
	else: beam_alpha = 1
	queue_redraw()

func _draw() -> void:
	if board.is_empty(): return
	var area = geometry()
	var step = area.size.x / board.width
	draw_style_box(_style(Color("101d2c"), Color("284356"), 20), area.grow(8))
	for y in range(board.height):
		for x in range(board.width):
			var rect = Rect2(area.position + Vector2(x, y) * step, Vector2.ONE * step)
			draw_rect(rect.grow(-1), Color("142333"))
			draw_circle(rect.get_center(), 1.4, Color("365063"))
	for p in board.panels:
		var rect = Rect2(area.position + Vector2(p.x, p.y) * step, Vector2(p.w, p.h) * step).grow(-4)
		var shrink = absf(cos(flip * PI)) if animation_panel == p.id else 1.0
		if p.axis == "v":
			rect.position.x += rect.size.x * (1 - shrink) / 2
			rect.size.x *= maxf(0.04, shrink)
		else:
			rect.position.y += rect.size.y * (1 - shrink) / 2
			rect.size.y *= maxf(0.04, shrink)
		var border = Color("527083").lerp(Color("72d6d0"), selected_strength) if p.id == selected else Color("527083")
		draw_style_box(_style(Color("284356"), border, 9), rect)
		if p.id == selected:
			var start = Vector2(rect.get_center().x, rect.position.y) if p.axis == "v" else Vector2(rect.position.x, rect.get_center().y)
			var end = Vector2(start.x, rect.end.y) if p.axis == "v" else Vector2(rect.end.x, start.y)
			draw_dashed_line(start, end, Color(0.72, 0.84, 0.9, 0.45), 1, 4)
	for segment in light.get("segments", []):
		var a = area.position + (segment[0] + Vector2.ONE * 0.5) * step
		var b = area.position + (segment[1] + Vector2.ONE * 0.5) * step
		if effects > 0: draw_line(a, b, Color(0.51, 0.91, 0.86, effects * 0.12), 10, true)
		draw_line(a, b, Color(0.51, 0.91, 0.86, beam_alpha), 2.0, true)
	for y in range(board.height):
		for x in range(board.width):
			var c = Model.cell(board, x, y)
			var center = area.position + (Vector2(x, y) + Vector2.ONE * 0.5) * step
			var r = step * 0.22
			if _animates_cell(x, y):
				var p = _panel_at(x, y)
				if p.axis == "v": center.x = area.position.x + (p.x + p.w * 0.5 + (x + 0.5 - p.x - p.w * 0.5) * absf(cos(flip * PI))) * step
				else: center.y = area.position.y + (p.y + p.h * 0.5 + (y + 0.5 - p.y - p.h * 0.5) * absf(cos(flip * PI))) * step
			match c.type:
				"mirror":
					var offset = Vector2(r, -r if c.dir % 2 == 0 else r)
					draw_line(center - offset + Vector2(0, 3), center + offset + Vector2(0, 3), Color("0b1322"), 6, true)
					draw_line(center - offset, center + offset, Color("c6e7f2"), 3, true)
				"emitter":
					draw_circle(center, r, Color("284356"))
					draw_arc(center, r, 0, TAU, 28, Color("72d6d0"), 2, true)
					var d = Vector2(Model.DIRS[c.dir])
					var normal = d.orthogonal()
					draw_colored_polygon(PackedVector2Array([center + d * r * 0.7, center - d * r * 0.4 + normal * r * 0.45, center - d * r * 0.4 - normal * r * 0.45]), Color("83e9dc"))
				"receiver":
					var active = light.active.has(y * board.width + x)
					var points = PackedVector2Array([center + Vector2(0, -r), center + Vector2(r * 0.8, 0), center + Vector2(0, r), center + Vector2(-r * 0.8, 0), center + Vector2(0, -r)])
					draw_colored_polygon(points, Color("a6f0d4") if active else Color("344e61"))
					draw_polyline(points, Color("a6f0d4") if active else Color("93a9ba"), 2, true)
					if active:
						draw_line(center + Vector2(-r * 0.4, 0), center + Vector2(-r * 0.1, r * 0.3), Color("0b1322"), 2, true)
						draw_line(center + Vector2(-r * 0.1, r * 0.3), center + Vector2(r * 0.4, -r * 0.3), Color("0b1322"), 2, true)
				"blocker":
					draw_rect(Rect2(center - Vector2.ONE * r, Vector2.ONE * 2 * r), Color("527083"), false, 2)
					draw_line(center - Vector2.ONE * r, center + Vector2.ONE * r, Color("527083"), 2)
				"splitter":
					draw_circle(center, r * 0.65, Color("9a9be8"))
					draw_line(center, center + Vector2(Model.DIRS[c.dir]) * r * 1.4, Color("f2f6fa"), 2, true)

func _style(color: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	return s

func _panel_at(x: int, y: int) -> Dictionary:
	for p in board.panels:
		if x >= p.x and x < p.x + p.w and y >= p.y and y < p.y + p.h: return p
	return {}

func _animates_cell(x: int, y: int) -> bool:
	return not animation_panel.is_empty() and _panel_at(x, y).get("id", "") == animation_panel

func cancel_gesture() -> void:
	owner_id = -99
	gesture = "CANCELLED"

func _gui_input(event: InputEvent) -> void:
	if busy or board.is_empty(): return
	var pressed = false
	var released = false
	var at = Vector2.ZERO
	var id = -1
	if event is InputEventScreenTouch:
		if event.canceled:
			cancel_gesture()
			return
		id = event.index
		pressed = event.pressed
		released = not event.pressed
		at = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		released = not event.pressed
		at = event.position
	elif event is InputEventScreenDrag:
		if event.index == owner_id: gesture = "FOLD_PREVIEW"
		return
	else: return
	if pressed and owner_id == -99:
		owner_id = id
		press_position = at
		gesture = "GESTURE_STARTED"
		var area = geometry()
		var coords = (at - area.position) / (area.size.x / board.width)
		if area.has_point(at):
			var p = _panel_at(int(coords.x), int(coords.y))
			selected = p.get("id", "")
			if not selected.is_empty():
				panel_selected.emit(selected)
				if not reduced_motion:
					if selection_tween: selection_tween.kill()
					selection_tween = create_tween()
					selection_tween.tween_method(func(v: float): selected_strength = v; queue_redraw(), 0.2, 1.0, 0.15)
		queue_redraw()
	elif released and id == owner_id:
		owner_id = -99
		gesture = "PANEL_SELECTED"
		var delta = at - press_position
		if delta.length() >= 24 and not selected.is_empty():
			var valid = false
			for p in board.panels:
				if p.id == selected and ((p.axis == "v" and absf(delta.x) > absf(delta.y) * 1.3) or (p.axis == "h" and absf(delta.y) > absf(delta.x) * 1.3)):
					fold_requested.emit(selected)
					valid = true
			if not valid: invalid_fold.emit()
	accept_event()

func animate_fold(id: String, commit: Callable) -> void:
	if busy: return
	busy = true
	gesture = "ANIMATING"
	animation_panel = id
	flip = 0
	if not reduced_motion:
		var tween = create_tween()
		tween.tween_method(func(value: float): flip = value; queue_redraw(), 0.0, 0.5, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
	commit.call()
	if not reduced_motion:
		var tween = create_tween()
		tween.tween_method(func(value: float): flip = value; queue_redraw(), 0.5, 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
	animation_panel = ""
	busy = false
	gesture = "PANEL_SELECTED"
	queue_redraw()
