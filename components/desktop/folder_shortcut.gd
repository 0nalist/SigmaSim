extends Control
class_name FolderShortcut

@export var item_id: int = 0
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
	DesktopLayoutManager.item_renamed.connect(_on_item_renamed)

func _on_item_renamed(changed_id: int, new_title: String) -> void:
	if changed_id == item_id:
		title_label.text = new_title

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.double_click and mb.pressed:
				_open_folder()
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

func _open_folder() -> void:
	var scene: PackedScene = preload("res://components/desktop/folder_window.tscn")
	var pane: Pane = scene.instantiate()
	if pane.has_method("setup"):
		pane.call_deferred("setup", item_id)
	WindowManager.launch_pane_instance(pane)
