extends Control
class_name BasePopupUI

func get_window_title() -> String:
	return "Popup"

@export var default_window_size: Vector2 = Vector2(360, 280)
@export var unique_popup_key: String = ""
@export var allow_multiple: bool = false

@export var window_can_close: bool = true
@export var window_can_minimize: bool = true
@export var window_can_maximize: bool = true

func _ready() -> void:
	get_parent().get_parent().get_parent().window_can_close = window_can_close
