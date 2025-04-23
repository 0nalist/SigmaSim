extends Control
signal step_valid(valid: bool)

@onready var pic_grid := %PicGrid

var selected_path: String = ""
var selected_button: TextureButton = null
var pic_folder_path := "res://assets/prof_pics/"

func _ready():
	var dir = DirAccess.open(pic_folder_path)
	if dir == null:
		printerr("Could not open profile picture directory:", pic_folder_path)
		return

	dir.list_dir_begin()

	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".png"):
			var full_path = pic_folder_path + file_name
			_add_picture_option(full_path)
		file_name = dir.get_next()

	dir.list_dir_end()

func _add_picture_option(path: String) -> void:
	var tex = load(path)
	if tex == null:
		printerr("Failed to load texture at:", path)
		return

	var pic_button = TextureButton.new()
	pic_button.texture_normal = tex
	pic_button.ignore_texture_size = true
	pic_button.stretch_mode = TextureButton.STRETCH_SCALE
	pic_button.custom_minimum_size = Vector2(128, 128)
	pic_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	pic_button.connect("pressed", func():
		_on_pic_selected(path, pic_button)
	)
	pic_grid.add_child(pic_button)


func _on_pic_selected(path: String, button: TextureButton):
	selected_path = path

	# Clear highlights
	for child in pic_grid.get_children():
		if child is TextureButton:
			child.modulate = Color.WHITE

	# Highlight selected
	button.modulate = Color.DODGER_BLUE

	emit_signal("step_valid", true)


func save_data():
	PlayerManager.user_data["profile_picture_path"] = selected_path
