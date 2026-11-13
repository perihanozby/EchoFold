extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/licenses")
	var output = FileAccess.open("res://assets/licenses/Godot.txt", FileAccess.WRITE)
	output.store_string(Engine.get_license_text())
	output.close()
	output = FileAccess.open("res://assets/licenses/Engine-third-party.txt", FileAccess.WRITE)
	for notice in Engine.get_copyright_info():
		output.store_string("\n" + str(notice.name) + "\n")
		for part in notice.parts:
			output.store_string("\n" + "\n".join(part.copyright) + "\n" + str(part.license) + "\n")
	for name_value in Engine.get_license_info():
		output.store_string("\n" + str(name_value) + "\n" + Engine.get_license_info()[name_value] + "\n")
	output.close()
	quit()
