extends Control
class_name AppShortcut

@export var item_id: int = 0
@export var app_name: String = ""
@export var title: String = ""
@export var icon: Texture2D

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %Title
@onready var context_menu: PopupMenu = %ContextMenu

var is_dragging: bool = false
var drag_offset: Vector2

func _ready() -> void:
    icon_rect.texture = icon
    title_label.text = title
    gui_input.connect(_on_gui_input)
    context_menu.add_item("Open", 0)
    context_menu.add_item("Delete", 1)
    context_menu.id_pressed.connect(_on_context_menu_id_pressed)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        if mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.double_click and mb.pressed:
                _open_app()
            elif mb.pressed:
                is_dragging = true
                drag_offset = mb.position
            else:
                if is_dragging:
                    is_dragging = false
                    DesktopLayoutManager.move_item(item_id, global_position)
        elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
            context_menu.position = mb.global_position
            context_menu.popup()
    elif event is InputEventMouseMotion:
        if is_dragging:
            global_position = get_global_mouse_position() - drag_offset

func _open_app() -> void:
    var item := DesktopLayoutManager.get_item(item_id)
    var data = item.get("data", {})
    if data is Dictionary and data.size() > 0:
        WindowManager.launch_app_by_name(app_name, item_id)
    else:
        WindowManager.launch_app_by_name(app_name)

func _on_context_menu_id_pressed(id: int) -> void:
    match id:
        0:
            _open_app()
        1:
            DesktopLayoutManager.delete_item(item_id)
