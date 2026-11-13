extends SceneTree
func _initialize() -> void:
	for item in ProjectSettings.get_property_list():
		if "file_logging" in item.name: print(item.name, " = ", ProjectSettings.get_setting(item.name))
	print("user_data = ", OS.get_user_data_dir())
	quit()
