extends Node

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var dir := DirAccess.open("res://tests")
	if dir == null:
		push_error("Failed to open tests directory")
		get_tree().quit(1)
		return
	dir.list_dir_begin()
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.ends_with("_test.gd"):
			var script_path = "res://tests/%s" % file_name
			print("Running %s" % script_path)
			var script = load(script_path)
			script.new()
	dir.list_dir_end()
	print("Finished running tests")
	get_tree().quit()
