extends Control
class_name FolderShortcut

@export var item_id: int = 0
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
	title_label.text = new_title
	title = new_title
	DesktopLayoutManager.rename_item(item_id, new_title)
	dialog.queue_free()

func _ctx_delete() -> void:
        DesktopLayoutManager.delete_item(item_id)

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
