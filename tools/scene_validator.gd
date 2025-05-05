@tool
extends EditorScript

func _run() -> void:
	validate_scene_folder("res://")  # You can change this to target specific folders
	print("✅ Scene validation complete.")


func validate_scene_folder(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		printerr("❌ Cannot open directory: ", path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				validate_scene_folder(path.path_join(file_name) + "/")
		elif file_name.ends_with(".tscn"):
			var full_path := path.path_join(file_name)
			_validate_scene(full_path)
		file_name = dir.get_next()

	dir.list_dir_end()


func _validate_scene(path: String) -> void:
	var packed_scene := load(path)
	if packed_scene == null or not packed_scene is PackedScene:
		printerr("❌ Failed to load PackedScene: ", path)
		return

	var instance = packed_scene.instantiate()
	if instance == null or not is_instance_valid(instance):
		printerr("🚫 Scene is corrupt or invalid: ", path)
	else:
		print("✅ OK: ", path)
