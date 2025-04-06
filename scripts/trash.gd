extends Window


func _ready() -> void:
	self.close_requested.connect(_on_close_requested)

func _on_close_requested():
	hide()
