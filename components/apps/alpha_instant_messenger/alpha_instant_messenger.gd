extends BaseAppUI
class_name AlphaInstantMessenger


func _ready() -> void:
	#default_window_size = Vector2(350, 420)
	app_title = "AIM"
#	app_icon = preload("res://assets/Tralalero_tralala.png")
	emit_signal("title_updated", app_title)

	update_ui()

func _on_window_close():
	print("closegrinder")
	hide()

func update_ui():
	pass
