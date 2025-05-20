extends Control
signal step_valid(valid: bool)

@onready var pic_grid := %PicGrid

@export var profile_pictures: Array[Texture2D] = []

var selected_texture: Texture2D = null
var selected_button: TextureButton = null

func _ready():
	for tex in profile_pictures:
		_add_picture_option(tex)

func _add_picture_option(tex: Texture2D) -> void:
	if tex == null:
		return

	var pic_button = TextureButton.new()
	pic_button.texture_normal = tex
	pic_button.ignore_texture_size = true
	pic_button.stretch_mode = TextureButton.STRETCH_SCALE
	pic_button.custom_minimum_size = Vector2(128, 128)
	pic_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pic_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	pic_button.pressed.connect(func(): _on_pic_selected(tex, pic_button))
	pic_grid.add_child(pic_button)

func _on_pic_selected(tex: Texture2D, button: TextureButton):
	selected_texture = tex

	# Clear highlights
	for child in pic_grid.get_children():
		if child is TextureButton:
			child.modulate = Color.WHITE

	# Highlight selected
	button.modulate = Color.DODGER_BLUE
	emit_signal("step_valid", true)

func save_data():
	# Store the path or resource UID depending on your save system
	PlayerManager.user_data["profile_picture_path"] = selected_texture.resource_path
