extends Pane
class_name Notepad

@onready var text_edit: TextEdit = %TextEdit

var item_id: int = 0

func _ready() -> void:
        text_edit.text_changed.connect(_on_text_changed)

func setup_custom(id: int) -> void:
        item_id = id
        var item = DesktopLayoutManager.get_item(id)
        var data: Dictionary = item.get("data", {})
        text_edit.text = data.get("text", "")
        window_title = item.get("title", window_title)

func _on_text_changed() -> void:
        if item_id != 0:
                DesktopLayoutManager.set_item_data(item_id, {"text": text_edit.text})

func get_custom_save_data() -> Dictionary:
        return {"item_id": item_id}

func load_custom_save_data(data: Dictionary) -> void:
        item_id = int(data.get("item_id", 0))
        if item_id != 0:
                var item = DesktopLayoutManager.get_item(item_id)
                var note_text = item.get("data", {}).get("text", "")
                text_edit.text = note_text
                window_title = item.get("title", window_title)

