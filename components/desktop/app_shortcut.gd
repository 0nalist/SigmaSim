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
var drag_origin_parent_id: int = 0

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
                                drag_origin_parent_id = int(DesktopLayoutManager.get_item(item_id).get("parent_id", 0))
                                if drag_origin_parent_id != 0:
                                        var old_global := global_position
                                        get_parent().remove_child(self)
                                        get_tree().root.add_child(self)
                                        global_position = old_global
                        else:
                                if is_dragging:
                                        is_dragging = false
                                        var target_parent := _find_drop_parent()
                                        DesktopLayoutManager.move_item(item_id, global_position, target_parent)
                                        if drag_origin_parent_id != 0 or target_parent != 0:
                                                queue_free()
        elif event is InputEventMouseMotion:
                if is_dragging:
                        global_position = get_global_mouse_position() - drag_offset

func _find_drop_parent() -> int:
        var mouse := get_global_mouse_position()
        if WindowManager:
                for win in WindowManager.open_windows.keys():
                        if win.pane is FolderWindow and win.get_global_rect().has_point(mouse):
                                return win.pane.folder_id
        for entry in DesktopLayoutManager.get_children_of(0):
                if entry.get("type", "") == "folder":
                        var icon_pos: Vector2 = entry.get("desktop_position", Vector2.ZERO)
                        var rect := Rect2(icon_pos, Vector2(64, 64))
                        if rect.has_point(mouse):
                                return int(entry.get("id", 0))
        return 0
