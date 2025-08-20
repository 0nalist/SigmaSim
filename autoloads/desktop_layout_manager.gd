extends Node
#Autoload DesktopLayoutManager

signal items_loaded()
signal item_created(item_id: int, data: Dictionary)
signal item_moved(item_id: int, position: Vector2)
signal item_deleted(item_id: int)
signal item_renamed(item_id: int, new_title: String)

var items: Dictionary = {}
var next_id: int = 1

func reset() -> void:
	items.clear()
	next_id = 1

func create_app_shortcut(app_name: String, title: String, icon_path: String, position: Vector2, parent_id: int = 0) -> int:
    var id: int = next_id
    next_id += 1
    var entry: Dictionary = {
        "id": id,
        "type": "app",
        "app_name": app_name,
        "title": title,
        "icon_path": icon_path,
        "desktop_position": position,
        "parent_id": parent_id,
        "child_ids": []
    }
    items[id] = entry
    if parent_id != 0 and items.has(parent_id):
        items[parent_id]["child_ids"].append(id)
    item_created.emit(id, entry)
    return id

func create_folder(title: String, icon_path: String, position: Vector2, parent_id: int = 0) -> int:
    var id: int = next_id
    next_id += 1
    var entry: Dictionary = {
        "id": id,
        "type": "folder",
        "title": title,
        "icon_path": icon_path,
        "desktop_position": position,
        "parent_id": parent_id,
        "child_ids": []
    }
    items[id] = entry
    if parent_id != 0 and items.has(parent_id):
        items[parent_id]["child_ids"].append(id)
    item_created.emit(id, entry)
    return id

func move_item(id: int, position: Vector2) -> void:
	if not items.has(id):
		return
	items[id]["desktop_position"] = position
	item_moved.emit(id, position)

func rename_item(id: int, new_title: String) -> void:
	if not items.has(id):
		return
	items[id]["title"] = new_title
	item_renamed.emit(id, new_title)

func delete_item(id: int) -> void:
    if not items.has(id):
        return
    var parent_id: int = int(items[id].get("parent_id", 0))
    if parent_id != 0 and items.has(parent_id):
        items[parent_id]["child_ids"].erase(id)
    items.erase(id)
    item_deleted.emit(id)

func get_item(id: int) -> Dictionary:
	return items.get(id, {})


func get_children_of(parent_id: int) -> Array:
	var results: Array = []
	for entry in items.values():
			if int(entry.get("parent_id", 0)) == parent_id:
					results.append(entry)
	return results


func get_save_data() -> Dictionary:
	return {
		"next_id": next_id,
		"items": _serialize_items()
	}

func _serialize_items() -> Array:
	var arr: Array = []
	for entry in items.values():
		var copy: Dictionary = entry.duplicate(true)
		copy["desktop_position"] = SaveManager.vector2_to_dict(entry.get("desktop_position", Vector2.ZERO))
		arr.append(copy)
	return arr

func load_from_data(data: Dictionary) -> void:
	reset()
	next_id = int(data.get("next_id", 1))
	var arr: Array = data.get("items", [])
	for entry in arr:
		var item: Dictionary = entry.duplicate(true)
		item["desktop_position"] = SaveManager.dict_to_vector2(entry.get("desktop_position", {}))
		var id: int = int(item.get("id", 0))
		if id <= 0:
			continue
		items[id] = item
	items_loaded.emit()
