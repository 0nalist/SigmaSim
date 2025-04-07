extends Window

class_name DesktopWindow


func _ready() -> void:
	print("DesktopWindow ready")
	close_requested.connect(_on_close_requested)

func _on_close_requested():
	_on_window_close()

func _on_window_close():
	print("closedesktopwindow")
	hide()
