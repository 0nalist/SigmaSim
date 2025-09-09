extends CustomButton
class_name AimContactButton

func _ready() -> void:
	custom_minimum_size = Vector2(170, 34)
	margin_left = 4
	margin_right = 4
	margin_top = 2
	margin_bottom = 2
	icon_texture = preload("res://assets/ui/buttons/redbuttonpressed.png")
	icon_location = "left"
	focus_mode = FocusMode.NONE
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
