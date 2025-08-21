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
var original_parent_id: int = 0

func _ready() -> void:
	icon_rect.texture = icon
	title_label.text = title
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click and mb.pressed:
				WindowManager.launch_app_by_name(app_name)
			elif mb.pressed:
				is_dragging = true
				drag_offset = mb.position
				var data: Dictionary = DesktopLayoutManager.get_item(item_id)
				original_parent_id = int(data.get("parent_id", 0))
				if get_parent() is GridContainer:
					var desktop: Node = get_tree().root.get_node_or_null("Main/DesktopEnv")
					if desktop != null:
						get_parent().remove_child(self)
						desktop.add_child(self)
						global_position = get_global_mouse_position() - drag_offset
			else:
				if is_dragging:
					is_dragging = false
					var target: Control = get_viewport().gui_pick(get_viewport().get_mouse_position())
					var new_parent: int = 0
					while target != null:
						if target is FolderShortcut:
							new_parent = target.item_id
							break
						if target is FolderWindow:
							new_parent = target.folder_id
							break
						target = target.get_parent()
					DesktopLayoutManager.move_item(item_id, global_position, new_parent)
					if new_parent != 0:
						queue_free()
	elif event is InputEventMouseMotion:
		if is_dragging:
			global_position = get_global_mouse_position() - drag_offset

