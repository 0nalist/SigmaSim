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
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var actions: Array = []
			var action_open: ContextAction = ContextAction.new()
			action_open.id = 0
			action_open.label = "Open Folder"
			action_open.method = "_open_folder"
			actions.append(action_open)
			var action_rename: ContextAction = ContextAction.new()
			action_rename.id = 1
			action_rename.label = "Rename Folder"
			action_rename.method = "_ctx_rename"
			actions.append(action_rename)
			var action_delete: ContextAction = ContextAction.new()
			action_delete.id = 2
			action_delete.label = "Delete Folder"
			action_delete.method = "_ctx_delete"
			actions.append(action_delete)
			ContextMenuManager.open_for(self, mb.global_position, actions)
	elif event is InputEventMouseMotion:
		if is_dragging:
			global_position = get_global_mouse_position() - drag_offset

func _open_folder() -> void:
	var scene: PackedScene = preload("res://components/desktop/folder_window.tscn")
	var pane: Pane = scene.instantiate()
	WindowManager.launch_pane_instance(pane, item_id)

func _ctx_rename() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Rename Folder"
	var line_edit: LineEdit = LineEdit.new()
	line_edit.text = title_label.text
	dialog.add_child(line_edit)
	dialog.confirmed.connect(Callable(self, "_on_rename_confirmed").bind(line_edit, dialog))
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_rename_confirmed(line_edit: LineEdit, dialog: AcceptDialog) -> void:
	var new_title: String = line_edit.text
	DesktopLayoutManager.rename_item(item_id, new_title)
	dialog.queue_free()

func _ctx_delete() -> void:
	DesktopLayoutManager.delete_item(item_id)
