extends SceneTree
func _initialize() -> void:
	var texture = load("res://assets/icons/echofold.svg") as Texture2D
	var image = texture.get_image()
	var error = image.save_png("res://assets/icons/boot.png")
	print("Brand PNG: ", error)
	quit(0 if error == OK else 1)
