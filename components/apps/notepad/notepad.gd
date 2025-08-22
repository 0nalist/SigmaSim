extends Pane
class_name Notepad

@onready var text_edit: TextEdit = %TextEdit

var item_id: int = 0
var _pending_text: String = ""
var _pending_title: String = ""
var _ready_done: bool = false

func _ready() -> void:
	_ready_done = true
	text_edit.text_changed.connect(_on_text_changed)

	# If we had pending data queued during load, apply it now
	if not _pending_text.is_empty():
		text_edit.text = _pending_text
		_pending_text = ""
	if not _pending_title.is_empty():
		window_title = _pending_title
		_pending_title = ""


func setup_custom(id: int) -> void:
	item_id = id
	var item: Dictionary = DesktopLayoutManager.get_item(id)
	var data: Dictionary = item.get("data", {})
	var note_text: String = data.get("text", "")
	var title: String = item.get("title", window_title)

	if _ready_done:
		text_edit.text = note_text
		window_title = title
	else:
		_pending_text = note_text
		_pending_title = title


func _on_text_changed() -> void:
	if item_id != 0:
		DesktopLayoutManager.set_item_data(item_id, {"text": text_edit.text})


func get_custom_save_data() -> Dictionary:
	return {"item_id": item_id}


func load_custom_save_data(data: Dictionary) -> void:
	item_id = int(data.get("item_id", 0))
	if item_id == 0:
		return

	var item: Dictionary = DesktopLayoutManager.get_item(item_id)
	var note_text: String = item.get("data", {}).get("text", "")
	var title: String = item.get("title", window_title)

	if _ready_done:
		text_edit.text = note_text
		window_title = title
	else:
		_pending_text = note_text
		_pending_title = title
