extends Pane
class_name FolderWindow

@export var folder_id: int = 0

@onready var grid: GridContainer = %Grid
@onready var scroll: ScrollContainer = %Scroll

func _ready() -> void:
	await get_tree().process_frame
	call_deferred("_update_grid_columns")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
			_update_grid_columns()


func setup_custom(id: int) -> void:
	folder_id = id
	var info: Dictionary = DesktopLayoutManager.get_item(id)
	window_title = info.get("title", "Folder")
	if not is_node_ready():
		await ready
	_populate()


func setup(id: int) -> void:
	setup_custom(id)

func _populate() -> void:
	for child in grid.get_children():
		child.queue_free()

	var items: Array = DesktopLayoutManager.get_children_of(folder_id)

	for entry in items:
			if entry.get("type", "") == "app":
					var ps: PackedScene = load("res://components/desktop/app_shortcut.tscn")
					var node: AppShortcut = ps.instantiate()
					node.item_id = entry.get("id", 0)
					node.title = entry.get("title", "")
					node.app_name = entry.get("app_name", "")
					_set_icon(node, entry)
					grid.add_child(node)
			else:
					var ps: PackedScene = load("res://components/desktop/folder_shortcut.tscn")
					var node: FolderShortcut = ps.instantiate()
					node.item_id = entry.get("id", 0)
					node.title = entry.get("title", "")
					_set_icon(node, entry)
					grid.add_child(node)
	_update_grid_columns()

func _set_icon(node: Control, entry: Dictionary) -> void:
	var icon_path: String = entry.get("icon_path", "")
	if icon_path != "":
		var tex: Texture2D = load(icon_path)
		if tex != null:
				node.icon = tex

func _update_grid_columns() -> void:
		if not is_node_ready():
				return
		var available_width: float = scroll.size.x
		var cols: int = max(1, int(available_width / 64.0))
		grid.columns = cols
		grid.custom_minimum_size = Vector2(available_width, 0)
