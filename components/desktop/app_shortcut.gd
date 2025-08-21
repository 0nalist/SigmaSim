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
var original_parent: Node

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
                               original_parent = get_parent()
                               var global_pos: Vector2 = global_position
                               get_tree().root.add_child(self)
                               global_position = global_pos
                       else:
                               if is_dragging:
                                       is_dragging = false
                                       var new_parent_id: int = _get_drop_parent_id()
                                       var old_parent_id: int = int(DesktopLayoutManager.get_item(item_id).get("parent_id", 0))
                                       DesktopLayoutManager.move_item(item_id, global_position, new_parent_id)
                                       if new_parent_id == old_parent_id:
                                               original_parent.add_child(self)
                                               global_position = get_global_mouse_position() - drag_offset
                                       else:
                                               queue_free()
       elif event is InputEventMouseMotion:
               if is_dragging:
                       global_position = get_global_mouse_position() - drag_offset

func _get_drop_parent_id() -> int:
       var node: Node = get_viewport().gui_pick(get_global_mouse_position())
       while node and not (node is FolderWindow):
               node = node.get_parent()
       if node and node is FolderWindow:
               return (node as FolderWindow).folder_id
       return 0
