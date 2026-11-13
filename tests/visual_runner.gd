extends SceneTree
const Store = preload("res://services/save_service.gd")
var scene: Control

func _initialize() -> void:
	call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png("res://build/" + name_value + ".png")
	print("CAPTURE ", name_value, " ", error)

func run() -> void:
	root.size = Vector2i(480, 960)
	root.content_scale_size = Vector2i(480, 960)
	scene = load("res://scenes/main.tscn").instantiate()
	scene.save_path_override = "res://build/visual_test_save.json"
	var file = FileAccess.open(scene.save_path_override, FileAccess.WRITE)
	file.store_string(JSON.stringify(Store.defaults()))
	file.close()
	root.add_child(scene)
	await create_timer(0.9).timeout
	await capture("home")
	scene.start_level(0)
	await create_timer(0.3).timeout
	await capture("first_light")
	scene.start_level(44)
	scene.show_hint()
	await create_timer(0.3).timeout
	await capture("resonance")
	for move in scene.Model.solve(scene.session.board).path:
		scene.board_view.selected = move
		scene.request_fold(move)
		await create_timer(0.4).timeout
	await capture("complete")
	root.size = Vector2i(360, 800)
	root.content_scale_size = Vector2i(360, 800)
	scene.size = Vector2(360,800)
	scene.start_level(13)
	await capture("compact")
	scene.words.language = "ar"
	scene.show_settings()
	await capture("arabic_settings")
	print("VISUAL CAPTURE COMPLETE")
	scene.free()
	await create_timer(0.2).timeout
	quit()
