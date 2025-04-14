extends BaseAppUI
class_name SigmaMail

func _ready() -> void:
	app_title = "Sigma Mail"
	#app_icon = preload("res://assets/AlphaOnline.png")
	emit_signal("title_updated", app_title)
