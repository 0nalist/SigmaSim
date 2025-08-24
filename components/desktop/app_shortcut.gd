extends Control
class_name AppShortcut

@export var item_id: int = 0
@export var app_name: String = ""
@export var title: String = ""
@export var icon: Texture2D

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %Title

var is_dragging: bool = false
var drag_offset: Vector2

func _ready() -> void:
	icon_rect.texture = icon
	title_label.text = title
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click and mb.pressed:
				WindowManager.launch_app_by_name(app_name, item_id)
			elif mb.pressed:
				is_dragging = true
				drag_offset = mb.position
			else:
				if is_dragging:
					is_dragging = false
					DesktopLayoutManager.move_item(item_id, global_position)
	elif event is InputEventMouseMotion:
		if is_dragging:
			global_position = get_global_mouse_position() - drag_offset
