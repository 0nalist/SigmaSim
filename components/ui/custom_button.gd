extends Button
class_name CustomButton

enum IconLocation { LEFT, RIGHT }

@export var margin_left: float = 0:
	set(value):
		margin_left = value
		_update_margins()

@export var margin_right: float = 0:
	set(value):
		margin_right = value
		_update_margins()

@export var margin_top: float = 0:
	set(value):
		margin_top = value
		_update_margins()

@export var margin_bottom: float = 0:
	set(value):
		margin_bottom = value
		_update_margins()

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		_update_margins()
		queue_redraw()

@export_enum("left", "right") var icon_location: String = "left":
	set(value):
		icon_location = value
		_update_margins()
		queue_redraw()

@export var icon_spacing: float = 4.0:
	set(value):
		icon_spacing = value
		_update_margins()
		queue_redraw()

func _ready() -> void:
	_update_margins()

func _update_margins() -> void:
	remove_theme_constant_override("content_margin_left")
	remove_theme_constant_override("content_margin_right")
	remove_theme_constant_override("content_margin_top")
	remove_theme_constant_override("content_margin_bottom")

	var icon_width: float = icon_texture.get_width() if icon_texture else 0
	if icon_location == "left":
		add_theme_constant_override("content_margin_left", margin_left + (icon_width + icon_spacing if icon_texture else 0))
		add_theme_constant_override("content_margin_right", margin_right)
	else:
		add_theme_constant_override("content_margin_left", margin_left)
		add_theme_constant_override("content_margin_right", margin_right + (icon_width + icon_spacing if icon_texture else 0))
	add_theme_constant_override("content_margin_top", margin_top)
	add_theme_constant_override("content_margin_bottom", margin_bottom)

func _draw() -> void:
	if icon_texture:
		var y: float = (size.y - icon_texture.get_height()) / 2
		var x: float
		if icon_location == "left":
			x = margin_left
		else:
			x = size.x - margin_right - icon_texture.get_width()
		draw_texture(icon_texture, Vector2(x, y))
