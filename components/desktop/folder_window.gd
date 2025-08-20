extends Pane
class_name FolderWindow

@export var folder_id: int = 0

@onready var grid: GridContainer = %Grid

func setup(id: int) -> void:
	folder_id = id
	var info: Dictionary = DesktopLayoutManager.get_item(id)
	window_title = info.get("title", "Folder")
	_populate()

func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()
       var items: Array = DesktopLayoutManager.get_children_of(folder_id)
	for entry in items:
		var scene_path: String
		if entry.get("type", "") == "app":
			scene_path = "res://components/desktop/app_shortcut.tscn"
		else:
			scene_path = "res://components/desktop/folder_shortcut.tscn"
		var ps: PackedScene = load(scene_path)
		var node: Control = ps.instantiate()
		node.item_id = entry.get("id", 0)
		node.title = entry.get("title", "")
		if node.has_variable("app_name"):
			node.app_name = entry.get("app_name", "")
		var icon_path: String = entry.get("icon_path", "")
		if icon_path != "":
			var tex: Texture2D = load(icon_path)
			node.icon = tex
		grid.add_child(node)
