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
					global_position = _clamp_to_desktop(global_position)
					DesktopLayoutManager.move_item(item_id, global_position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			context_menu.position = mb.global_position
			context_menu.reset_size()
			context_menu.popup()
	elif event is InputEventMouseMotion:
		if is_dragging:
			var new_pos = get_global_mouse_position() - drag_offset
			global_position = _clamp_to_desktop(new_pos)

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

func _clamp_to_desktop(pos: Vector2) -> Vector2:
	var viewport_size = get_viewport().get_visible_rect().size
	var topbar_height = WindowManager.get_topbar_height() if WindowManager and WindowManager.has_method("get_topbar_height") else 0
	var taskbar_height = WindowManager.get_taskbar_height() if WindowManager and WindowManager.has_method("get_taskbar_height") else 0
	var min_pos = Vector2(0, topbar_height)
	var max_pos = Vector2(viewport_size.x - size.x, viewport_size.y - taskbar_height - size.y)
	return pos.clamp(min_pos, max_pos)
